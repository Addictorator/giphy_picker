import 'dart:async';
import 'package:giphy_picker/src/model/giphy_repository.dart';
import 'package:giphy_picker/src/widgets/giphy_context.dart';
import 'package:giphy_picker/src/widgets/giphy_thumbnail_grid.dart';
import 'package:flutter/material.dart';

class GiphySearchPage extends StatefulWidget {
  @override
  _GiphySearchPageState createState() => _GiphySearchPageState();
}

class _GiphySearchPageState extends State<GiphySearchPage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _repoController = StreamController<GiphyRepository>();
  @override
  void initState() {
// initiate search on next frame (we need context)
    Future.delayed(Duration.zero, () {
      final giphy = GiphyContext.of(context);
      _search(giphy);
    });
    super.initState();
  }

  @override
  void dispose() {
    _repoController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final giphy = GiphyContext.of(context);
    return Scaffold(
        appBar: AppBar(
            title: TextField(style: const TextStyle(color: Colors.white, fontSize: 15.0), controller: _textController, decoration: InputDecoration.collapsed(hintText: 'Search Giphy', hintStyle: TextStyle(color: Colors.white70)
            ), onChanged: (value) => _delayedSearch(giphy, value))),
        body: SafeArea(
            child: Column(children: <Widget>[
              Expanded(
                  child: StreamBuilder(
                      stream: _repoController.stream,
                      builder: (BuildContext context, AsyncSnapshot<GiphyRepository> snapshot) {
                        if (snapshot.hasData) {
                          return snapshot.data.totalCount > 0
                              ? NotificationListener(
                            child: RefreshIndicator(child: GiphyThumbnailGrid(key: Key('${snapshot.data.hashCode}'), repo: snapshot.data, scrollController: _scrollController), onRefresh: () => _search(giphy, term: _textController.text)),
                            onNotification: (n) {
// hide keyboard when scrolling
                              if (n is UserScrollNotification) {
                                FocusScope.of(context).requestFocus(FocusNode());
                              }
                              return false;
                            },
                          )
                              : Center(child: Text('No results'));
                        }
                        return Center(child: CircularProgressIndicator());
                      }))
            ]), bottom: false));
  }

  void _delayedSearch(GiphyContext giphy, String term) => Future.delayed(Duration(milliseconds: 500), () => _search(giphy, term: term));
  Future _search(GiphyContext giphy, {String term = ''}) async {
// skip search if term does not match current search text
    if (term != _textController.text) {
      return;
    }
    try {
// search, or trending when term is empty
      final repo = await (term.isEmpty ? GiphyRepository.trending(apiKey: giphy.apiKey, rating: giphy.rating, onError: giphy.onError) : GiphyRepository.search(apiKey: giphy.apiKey, query: term, rating: giphy.rating, lang: giphy.language, onError: giphy.onError));
// scroll up
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
      _repoController.add(repo);
    } catch (error) {
      giphy.onError(error);
    }
  }
}