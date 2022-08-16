import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:comic_nyaa/library/mio/core/mio_loader.dart';
import 'package:comic_nyaa/utils/http.dart';
import 'package:comic_nyaa/views/detail/comic_detail_view.dart';
import 'package:comic_nyaa/views/detail/image_detail_view.dart';
import 'package:comic_nyaa/views/detail/video_detail_view.dart';
import 'package:comic_nyaa/views/subscribe_view.dart';
import 'package:dio/dio.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:comic_nyaa/library/mio/model/site.dart';
import 'package:comic_nyaa/library/mio/core/mio.dart';
import 'package:comic_nyaa/models/typed_model.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shimmer/shimmer.dart';

import '../app/global.dart';
import '../models/typed_model.dart';

class MainView extends StatefulWidget {
  const MainView({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> with TickerProviderStateMixin {
  final globalKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  final FloatingSearchBarController _floatingSearchBarController =
      FloatingSearchBarController();
  late final TabController _tabController =
      TabController(length: 3, vsync: this, initialIndex: 0);
  final Map<int, double> _heightCache = {};
  DateTime? currentBackPressTime = DateTime.now();
  List<TypedModel> _models = [];
  List<Site> _sites = [];
  List<String> _autosuggest = [];
  int _currentSiteId = 920;
  int _page = 1;
  String _keywords = '';
  bool _isLoading = false;
  bool _isRefresh = false;
  bool _isNotMore = false;
  int _lastScrollPosition = 0;
  int _lastScrollTime = 0;

  Future<List<TypedModel>> _getModels() async {
    if (_isLoading) return [];
    _isLoading = true;
    try {
      print('PPPPPPPPPPPPPPPPPPPPPPPPPPAGE: $_page');
      final results = await (Mio(_sites.firstWhere(
              (site) => site.id == _currentSiteId,
              orElse: () => _sites[0]))
            ..setPage(_page)
            ..setKeywords(_keywords))
          .parseSite();
      final images = List.of(results.map((item) => TypedModel.fromJson(item)));
      // print('IMAGES LENGTH: $images');
      if (images.isEmpty) {
        // _isNotMore = true;
        Fluttertoast.showToast(msg: '已经到底了');
      }
      return images;
    } catch (e) {
      // rethrow;
      Fluttertoast.showToast(msg: 'ERROR: $e');
    } finally {
      _isLoading = false;
    }
    return [];
  }

  Future<List<TypedModel>> _getNext() async {
    ++_page;
    final models = await _getModels();
    if (models.isEmpty) {
      --_page;
      // if (_isNotMore) return [];
    }
    _refreshController.loadComplete();
    setState(() => _models.addAll(models));
    return models;
  }

  Future<List<TypedModel>> _onSearch(String keywords) async {
    // _refreshController.footerMode?.setValueWithNoNotify(LoadStatus.idle);
    // _isNotMore = false;

    _isRefresh = true;
    setState(() {
      _models = [];
      _heightCache.clear();
    });
    _page = 1;
    _keywords = keywords;
    final models = await _getModels();
    _isRefresh = false;
    _refreshController.refreshCompleted();
    setState(() => _models = models);
    return models;
  }

  _onRefresh() async {
    await _onSearch(_keywords);
  }

  Future<void> _initialize() async {
    await _checkUpdate();
    final sites = await RuleLoader.loadFromDirectory(await Config.ruleDir);
    sites.forEachIndexed(
        (i, element) => print('$i: [${element.id}]${element.name}'));
    setState(() {
      _sites = sites;
      _currentSiteId = _currentSiteId < 0 ? _sites[0].id! : _currentSiteId;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshController.requestRefresh();
    });
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent) {
        if (!_isLoading) {
          _getNext();
        }
      }
      if (_scrollController.position.pixels < 128) {
        _floatingSearchBarController.isHidden
            ? _floatingSearchBarController.show()
            : null;
      } else if (_scrollController.position.pixels > _lastScrollPosition + 64) {
        _lastScrollPosition = _scrollController.position.pixels.toInt();
        _floatingSearchBarController.isVisible
            ? _floatingSearchBarController.hide()
            : null;
      } else if (_scrollController.position.pixels < _lastScrollPosition - 64) {
        _lastScrollPosition = _scrollController.position.pixels.toInt();
        _floatingSearchBarController.isHidden
            ? _floatingSearchBarController.show()
            : null;
      }
      _lastScrollTime = DateTime.now().millisecondsSinceEpoch;
    });
  }

  void _jump(TypedModel model) {
    Widget? target;
    switch (model.type) {
      case 'image':
        target = ImageDetailView(models: [model]);
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

  Site? get _currentSite {
    return _sites.firstWhereOrNull((site) => site.id == _currentSiteId);
  }

  _checkUpdate() async {
    final ruleDir = (await Config.ruleDir);
    await RuleLoader.loadFromDirectory(ruleDir);
    if (RuleLoader.sites.isEmpty) {
      await _updateSubscribe(ruleDir);
    }
  }

  Future<void> _updateSubscribe(Directory dir) async {
    final savePath = dir.join('rules.zip').path;
    await Http.client().download('https://hlo.li/static/rules.zip', savePath);
    await RuleLoader.loadFromDirectory(dir);
  }

  @override
  void initState() {
    _initialize();
    super.initState();
  }

  Future<bool> onWillPop() {
    if (globalKey.currentState?.isDrawerOpen == true) {
      globalKey.currentState?.closeDrawer();
      return Future.value(false);
    }
    if (globalKey.currentState?.isEndDrawerOpen == true) {
      globalKey.currentState?.closeEndDrawer();
      return Future.value(false);
    }
    DateTime now = DateTime.now();
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime!) > const Duration(seconds: 2)) {
      currentBackPressTime = now;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('再按一次退出')));
      return Future.value(false);
    }
    return Future.value(true);
  }

  Widget buildDrawer() {
    return Drawer(
        child: ListView(padding: EdgeInsets.zero, children: [
      Stack(children: [
        CachedNetworkImage(
          imageUrl:
              'https://cdn.jsdelivr.net/gh/nyarray/LoliHost/images/94d6d0e7be187770e5d538539d95a12a.jpeg',
          fit: BoxFit.cover,
          height: 256,
        ),
        Positioned.fill(
          child: Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  gradient: LinearGradient(
                      begin: FractionalOffset.topCenter,
                      end: FractionalOffset.bottomCenter,
                      colors: [
                        Colors.grey.withOpacity(0.0),
                        Colors.black45,
                      ],
                      stops: const [
                        0.0,
                        1.0
                      ])),
              padding: const EdgeInsets.all(8),
              alignment: Alignment.bottomLeft,
              child: const Text('ポトフちゃんとワトラちゃんがすごくかわいいです！',
                  style: TextStyle(color: Colors.white, fontSize: 18))),
        ),
      ]),
      Container(height: 8),
      ListTile(
          title: const Text('主页'),
          selected: true,
          selectedTileColor: Color.fromRGBO(0, 127, 127, .2),
          onTap: () {},
          iconColor: Colors.teal,
          leading: const Icon(Icons.home)),
      ListTile(
          title: const Text('订阅'),
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (ctx) => const SubscribeView()));
          },
          iconColor: Colors.black87,
          leading: const Icon(Icons.collections_bookmark)),
      ListTile(
          title: const Text('下载'),
          onTap: () {},
          iconColor: Colors.black87,
          leading: const Icon(Icons.download)),
      ListTile(
          title: const Text('设置'),
          onTap: () {},
          iconColor: Colors.black87,
          leading: const Icon(Icons.tune))
    ]));
  }

  Widget buildEndDrawer() {
    return Drawer(
      width: 256,
        elevation: 8,
        child: Material(
            child: Column(children: [
      CachedNetworkImage(
        imageUrl:
            'https://cdn.jsdelivr.net/gh/nyarray/LoliHost/images/7c4f1d7ea2dadd3ca835b9b2b9219681.webp',
        fit: BoxFit.cover,
        height: 192,
      ),
      Flexible(
          child: ListView.builder(
              padding: const EdgeInsets.only(top: 8),
              itemCount: _sites.length,
              itemBuilder: (ctx, index) {
                return Material(
                    // elevation: _currentSiteId == _sites[index].id ? 4 : 0,
                    child: InkWell(
                        onTap: () {
                          _currentSiteId = _sites[index].id!;
                          _refreshController.requestRefresh();
                          globalKey.currentState?.closeEndDrawer();
                        },
                        child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: _currentSiteId == _sites[index].id
                                  ? const Color.fromRGBO(0, 127, 127, .12)
                                  : null,
                            ),
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 8),
                            child: Row(
                              children: [
                                SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: CachedNetworkImage(
                                      imageUrl: _sites[index].icon ?? '',
                                      fit: BoxFit.cover,
                                      errorWidget: (ctx, url, error) =>
                                          const Icon(Icons.image_not_supported,
                                              size: 32),
                                    )),
                                Container(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Text(
                                      style: TextStyle(
                                          fontFamily: 'sans-serif',
                                          fontSize: 18,
                                          color:
                                              _currentSiteId == _sites[index].id
                                                  ? Colors.teal
                                                  : null),
                                      _sites[index].name ?? '',
                                      textAlign: TextAlign.start,
                                    ))
                              ],
                            ))));
              })),
    ])));
  }

  Future<ImageInfo> getImageInfo(ImageProvider image) async {
    final c = Completer<ImageInfo>();
    image.resolve(const ImageConfiguration()).addListener(
        ImageStreamListener((ImageInfo i, bool _) => c.complete(i)));
    return c.future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: globalKey,
      resizeToAvoidBottomInset: false,
      drawerEdgeDragWidth: 64,
      drawerEnableOpenDragGesture: true,
      endDrawerEnableOpenDragGesture: true,
      drawer: buildDrawer(),
      endDrawer: buildEndDrawer(),
      body: WillPopScope(
          onWillPop: onWillPop,
          child: Stack(
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
                            distance: 48,
                            offset: 96,
                          ),
                          // footer: CustomFooter(
                          //   builder: ( context, mode){
                          //     Widget body ;
                          //     if (_isEnd) {
                          //       body = Text("No more Data");
                          //     }
                          //     else if(mode==LoadStatus.idle){
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
                              padding: const EdgeInsets.fromLTRB(
                                  8, kToolbarHeight + 48, 8, 0),
                              crossAxisCount: 3,
                              mainAxisSpacing: 8.0,
                              crossAxisSpacing: 8.0,
                              itemCount: _models.length,
                              controller: _scrollController,
                              // physics: const BouncingScrollPhysics(),
                              itemBuilder: (context, index) {
                                return Material(
                                    clipBehavior: Clip.hardEdge,
                                    elevation: 2,
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(4.0)),
                                    child: InkWell(
                                        onTap: () => _jump(_models[index]),
                                        child: Column(
                                          children: [
                                            CachedNetworkImage(
                                              // height: _heightCache[index] ?? 160,
                                              imageUrl:
                                                  _models[index].coverUrl ?? '',
                                              fadeInDuration: const Duration(
                                                  milliseconds: 200),
                                              fadeOutDuration: const Duration(
                                                  milliseconds: 200),
                                              fit: BoxFit.cover,
                                              errorWidget: (ctx, url, error) =>
                                                  const AspectRatio(
                                                      aspectRatio: 1,
                                                      child: Icon(
                                                        Icons
                                                            .image_not_supported,
                                                        size: 64,
                                                      )),
                                              placeholder: (ctx, text) =>
                                                  const AspectRatio(
                                                      aspectRatio: 0.66,
                                                      child:
                                                          SpinKitDoubleBounce(
                                                              color:
                                                                  Colors.teal)),
                                              httpHeaders: _currentSite?.headers,
                                              // )
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                _models[index].title ?? '',
                                                maxLines: 3,
                                              ),
                                            )
                                          ],
                                        )));
                              })),
                    ),
                  ])),
              // buildMap(),
              // buildBottomNavigationBar(),
              buildFloatingSearchBar(),
            ],
          )),
      // );
      // ]),
      // bottomNavigationBar: BottomAppBar(
      //   color: Colors.white,
      //   shape: const CircularNotchedRectangle(), // 底部导航栏打一个圆形的洞
      //   child: TabBar(
      //     controller: _tabController,
      //     tabs: const <Widget>[
      //       Tab(
      //         icon: Icon(
      //           Icons.cloud_outlined,
      //           color: Colors.teal,
      //         ),
      //       ),
      //       Tab(
      //         icon: Icon(
      //           Icons.beach_access_sharp,
      //           color: Colors.teal,
      //         ),
      //       ),
      //       Tab(
      //         icon: Icon(
      //           Icons.brightness_5_sharp,
      //           color: Colors.teal,
      //         ),
      //       ),
      //     ],
      //   ),
      // ),
      // floatingActionButtonLocation:  FloatingActionButtonLocation.endDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => globalKey.currentState?.openEndDrawer(),
        tooltip: 'Export',
        child: const Icon(Icons.arrow_back),
      ),
    );
  }

  Widget buildFloatingSearchBar() {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return FloatingSearchBar(
      title: Text(_keywords.isEmpty ? 'Search...' : _keywords, style: TextStyle(fontFamily: 'sans-serif', fontSize: 14, color: _keywords.isEmpty ? Colors.black54 : Colors.black87),),
      controller: _floatingSearchBarController,
      automaticallyImplyDrawerHamburger: false,
      automaticallyImplyBackButton: false,
      hint: 'Search...',
      scrollPadding: const EdgeInsets.only(top: 8, bottom: 8),
      // implicitDuration: const Duration(milliseconds: 250),
      transitionDuration: const Duration(milliseconds: 300),
      transitionCurve: Curves.easeInOut,
      // physics: const BouncingScrollPhysics(),
      axisAlignment: isPortrait ? 0.0 : -1.0,
      openAxisAlignment: 0.0,
      width: isPortrait ? 600 : 500,
      debounceDelay: const Duration(milliseconds: 500),
      // clearQueryOnClose: false,
      hintStyle: const TextStyle(fontFamily: 'sans-serif', fontSize: 14),
      queryStyle: const TextStyle(fontFamily: 'sans-serif', fontSize: 14),
      onQueryChanged: (query) async {
        final value = await Dio().get(
            'https://danbooru.donmai.us/autocomplete.json?search[query]=$query&search[type]=tag_query&limit=10');
        final result = List<Map<String, dynamic>>.from(value.data);
        setState(() {
          _autosuggest = result.map((item) => item['value'] as String).toList();

          print('_autosuggest: $_autosuggest');
        });
      },

      // Specify a custom transition to be used for
      // animating between opened and closed stated.
      transition: CircularFloatingSearchBarTransition(),
      // transition: SlideFadeFloatingSearchBarTransition(),
      leadingActions: [
        FloatingSearchBarAction.hamburgerToBack(),
        FloatingSearchBarAction(
            showIfOpened: true,
            child: CachedNetworkImage(
                imageUrl: _currentSite?.icon ?? '',
                errorWidget: (ctx, url, error) {
                  return Text(_currentSite?.name?.substring(0, 1) ?? '?',
                    style: const TextStyle(
                        fontFamily: 'sans-serif',
                        fontSize: 18,
                      color: Colors.teal
                    ),
                  );
                })),
      ],
      actions: [
        FloatingSearchBarAction(
          showIfOpened: false,
          child: CircularButton(
            // icon: const Icon(CupertinoIcons.square_grid_2x2),
            icon: const Icon(Icons.extension),
            // icon: const Icon( CupertinoIcons.square_stack_3d_up),
            onPressed: () {
              globalKey.currentState?.openEndDrawer();
            },
          ),
        ),
        // FloatingSearchBarAction.icon(icon: Icon., onTap: onTap)
        FloatingSearchBarAction.searchToClear(
          showIfClosed: false,
        ),
      ],
      onSubmitted: (query) {
        _keywords = query;
        _refreshController.requestRefresh();
        _floatingSearchBarController.close();
      },
      builder: (context, transition) {
        return
            // ClipRRect(
            // borderRadius: BorderRadius.circular(4),
            // child:
            Material(
          color: Colors.white,
          elevation: 4.0,
          borderRadius: BorderRadius.circular(4),
          child: Column(
            // mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _autosuggest.map((query) {
              return Material(
                  child: InkWell(
                      onTap: () {
                        _keywords = query;
                        _refreshController.requestRefresh();
                        _floatingSearchBarController.query = query;
                        _floatingSearchBarController.close();
                      },
                      child: Container(
                          padding: const EdgeInsets.only(left: 20),
                          height: 48,
                          alignment: Alignment.centerLeft,
                          decoration: const BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(color: Colors.black12))),
                          child: Text(
                            query,
                            style: const TextStyle(
                                fontFamily: 'sans-serif', fontSize: 14),
                          ))));
            }).toList(),
          ),
          // ),
        );
      },
    );
  }
}
