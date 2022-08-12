import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive.dart';
import 'package:collection/collection.dart';
import 'package:comic_nyaa/library/mio/core/mio_loader.dart';
import 'package:comic_nyaa/views/detail/comic_detail_view.dart';
import 'package:comic_nyaa/views/detail/image_detail_view.dart';
import 'package:comic_nyaa/views/detail/video_detail_view.dart';
import 'package:dio/dio.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:comic_nyaa/library/mio/model/site.dart';
import 'package:comic_nyaa/library/mio/core/mio.dart';
import 'package:comic_nyaa/models/typed_model.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../app/global.dart';
import '../models/typed_model.dart';

class MainView extends StatefulWidget {
  const MainView({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  final globalKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  final FloatingSearchBarController _floatingSearchBarController = FloatingSearchBarController();
  final Map<int, double> _heightCache = {};
  List<TypedModel> _models = [];
  List<Site> _sites = [];
  List<String> _autosuggest = [];
  int _currentSiteId = 920;
  int _page = 1;
  String _keywords = '';
  bool _isLoading = false;
  bool _isNext = false;
  bool _isRefresh = false;

  Future<List<TypedModel>> _getModels() async {
    _isLoading = true;
    try {
      final results = await (Mio(_sites.firstWhere((site) => site.id == _currentSiteId, orElse: () => _sites[0]))
            ..setPage(_page)
            ..setKeywords(_keywords))
          .parseSite();
      final images = List.of(results.map((item) => TypedModel.fromJson(item)));
      return images;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
    }
    return [];
  }

  Future<List<TypedModel>> _getNext() async {
    _isNext = true;
    ++_page;
    final models = await _getModels();
    _isNext = false;
    setState(() => _models.addAll(models));
    return models;
  }

  Future<List<TypedModel>> _onSearch(String keywords) async {
    _isRefresh = true;
    setState(() {
      _models.clear();
      _heightCache.clear();
    });
    _page = 1;
    _keywords = keywords;
    final models = await _getModels();
    _isRefresh = false;
    _refreshController.loadComplete();
    setState(() => _models = models);
    return models;
  }

  _onRefresh() async {
    await _onSearch(_keywords);
    setState(() {
      _refreshController.refreshCompleted();
    });
  }

  Future<void> _updateSubscribe() async {
    final savePath = (await Config.ruleDir).concatPath('rules.zip').path;
    print('savePath: $savePath');
    await Dio().download('https://hlo.li/static/rules.zip', savePath);
  }

  Future<void> _initialize() async {
    await _updateSubscribe();

    final sites = await RuleLoader.getRules(await Config.ruleDir);
    sites.forEachIndexed((i, element) => print('$i: [${element.id}]${element.name}'));
    setState(() {
      _sites = sites;
      _currentSiteId = _currentSiteId < 0 ? _sites[0].id! : _currentSiteId;
    });
    final models = await _getModels();
    setState(() => _models = models);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent) {
        if (!_isLoading) {
          _getNext();
        }
      }
    });
  }

  void _jump(TypedModel model) {
    Widget? target;
    switch (model.type) {
      case 'image':
        target = ImageDetailView(model: model);
        break;
      case 'video':
        target = VideoDetailView(model: model);
        break;
      case 'comic':
        target = ComicDetailView(model: model);
        break;
    }
    if (target != null) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => target!));
    }
  }

  @override
  void initState() {
    _initialize();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: globalKey,
      resizeToAvoidBottomInset: false,
      drawer: const Drawer(
        child: Text('Teetd'),
      ),
      endDrawer: Drawer(
          child: Material(
              child: Column(children: [
        ExtendedImage.network('https://cdn.jsdelivr.net/gh/nyarray/LoliHost/images/7c4f1d7ea2dadd3ca835b9b2b9219681.webp'),
        Flexible(
            child: ListView.builder(
                itemCount: _sites.length,
                itemBuilder: (ctx, index) {
                  return Material(
                      elevation: _currentSiteId == _sites[index].id ? 4 : 0,
                      child: InkWell(
                          onTap: () {
                            _currentSiteId = _sites[index].id!;
                            _onRefresh();
                            _refreshController.requestRefresh();
                            globalKey.currentState?.closeEndDrawer();
                          },
                          child: Container(
                              decoration: BoxDecoration(
                                color: _currentSiteId == _sites[index].id ? const Color.fromRGBO(0, 127, 127, .12) : null,
                              ),
                              // border: Border(bottom: BorderSide(color: const Color.fromRGBO(0, 127, 127, .12)))),
                              // height: 40,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 8),
                              child: Row(
                                children: [
                                  SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: ExtendedImage.network(
                                        _sites[index].icon ?? '',
                                        fit: BoxFit.cover,
                                      )),
                                  Container(
                                      padding: EdgeInsets.only(left: 8),
                                      child: Text(
                                        _sites[index].name ?? '',
                                        textAlign: TextAlign.start,
                                      ))
                                ],
                              ))));
                })),
      ]))),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
              child: Column(children: [
                Flexible(
                  child: SmartRefresher(
                      enablePullDown: true,
                      enablePullUp: true,
                      header: const WaterDropMaterialHeader(
                        distance: 32,
                        offset: 96,
                      ),
                      // footer: CustomFooter(
                      //   builder: (BuildContext context,LoadStatus mode){
                      //     Widget body ;
                      //     if(mode==LoadStatus.idle){
                      //       body =  Text("pull up load");
                      //     }
                      //     else if(mode==LoadStatus.loading){
                      //       body =  CupertinoActivityIndicator();
                      //     }
                      //     else if(mode == LoadStatus.failed){
                      //       body = Text("Load Failed!Click retry!");
                      //     }
                      //     else if(mode == LoadStatus.canLoading){
                      //       body = Text("release to load more");
                      //     }
                      //     else{
                      //       body = Text("No more Data");
                      //     }
                      //     return Container(
                      //       height: 55.0,
                      //       child: Center(child:body),
                      //     );
                      //   },
                      // ),
                      controller: _refreshController,
                      onRefresh: () => _onRefresh(),
                      // onLoading: _onLoading,
                      child: MasonryGridView.count(
                          padding: const EdgeInsets.fromLTRB(8, kToolbarHeight + 48, 8, 0),
                          crossAxisCount: 3,
                          mainAxisSpacing: 8.0,
                          crossAxisSpacing: 8.0,
                          itemCount: _models.length,
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            return Material(
                                clipBehavior: Clip.hardEdge,
                                elevation: 2.0,
                                borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                                child: InkWell(
                                    onTap: () => _jump(_models[index]),
                                    child: Column(
                                      children: [
                                        ExtendedImage.network(
                                          _models[index].coverUrl ?? '',
                                          height: _heightCache[index],
                                          afterPaintImage: (canvas, rect, image, paint) {
                                            if (_heightCache[index] == null) _heightCache[index] = rect.height;
                                          },
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(_models[index].title ?? ''),
                                        )
                                      ],
                                    )));
                          })),
                ),
                // _isNext ? const Text('Loading...') : Container()
              ])),

          // buildMap(),
          // buildBottomNavigationBar(),
          buildFloatingSearchBar(),
        ],
      ),
      // );
      // ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => globalKey.currentState?.openEndDrawer(),
        tooltip: 'Increment',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget buildFloatingSearchBar() {
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return FloatingSearchBar(
      controller: _floatingSearchBarController,
      clearQueryOnClose: false,
      automaticallyImplyDrawerHamburger: false,
      hint: 'Search...',
      scrollPadding: const EdgeInsets.only(top: 16, bottom: 56),
      transitionDuration: const Duration(milliseconds: 500),
      transitionCurve: Curves.easeInOut,
      // physics: const BouncingScrollPhysics(),
      axisAlignment: isPortrait ? 0.0 : -1.0,
      openAxisAlignment: 0.0,
      width: isPortrait ? 600 : 500,
      debounceDelay: const Duration(milliseconds: 500),
      onQueryChanged: (query) async {
        final value = await Dio()
            .get('https://danbooru.donmai.us/autocomplete.json?search[query]=$query&search[type]=tag_query&limit=10');
        final result = List<Map<String, dynamic>>.from(value.data);
        setState(() {
          _autosuggest = result.map((item) => item['value'] as String).toList();

          print('_autosuggest: $_autosuggest');
        });
      },
      // Specify a custom transition to be used for
      // animating between opened and closed stated.
      transition: CircularFloatingSearchBarTransition(),
      leadingActions: [
        FloatingSearchBarAction.hamburgerToBack(),
      ],
      actions: [
        FloatingSearchBarAction(
          showIfOpened: false,
          child: CircularButton(
            icon: const Icon(CupertinoIcons.square_grid_2x2),
            // icon: const Icon( CupertinoIcons.square_stack_3d_up),
            onPressed: () {
              globalKey.currentState?.openEndDrawer();
            },
          ),
        ),
        FloatingSearchBarAction.searchToClear(
          showIfClosed: false,
        ),
      ],
      onSubmitted: (query) {
        _onSearch(query);
        _floatingSearchBarController.close();
      },
      builder: (context, transition) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Material(
            color: Colors.white,
            elevation: 4.0,
            child: Column(
              // mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _autosuggest.map((query) {
                return Material(
                    child: InkWell(
                        onTap: () {
                          _onSearch(query);
                          _floatingSearchBarController.query = query;
                          _floatingSearchBarController.close();
                        },
                        child: Container(
                            padding: const EdgeInsets.only(left: 20),
                            height: 48,
                            alignment: Alignment.centerLeft,
                            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black12))),
                            child: Text(
                              query,
                              textAlign: TextAlign.center,
                            ))));
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
