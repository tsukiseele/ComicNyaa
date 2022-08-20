import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:comic_nyaa/library/mio/core/mio_loader.dart';
import 'package:comic_nyaa/utils/http.dart';
import 'package:comic_nyaa/views/detail/comic_detail_view.dart';
import 'package:comic_nyaa/views/detail/image_detail_view.dart';
import 'package:comic_nyaa/views/detail/video_detail_view.dart';
import 'package:comic_nyaa/views/settings_view.dart';
import 'package:comic_nyaa/views/subscribe_view.dart';
import 'package:comic_nyaa/views/widget/dynamic_tab_view.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:comic_nyaa/library/mio/model/site.dart';
import 'package:comic_nyaa/models/typed_model.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';

import '../app/global.dart';
import '../models/typed_model.dart';
import '../utils/string_extensions.dart';
import 'pages/gallery_view.dart';

class MainView extends StatefulWidget {
  const MainView({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> with TickerProviderStateMixin {
  final globalKey = GlobalKey<ScaffoldState>();
  final FloatingSearchBarController _floatingSearchBarController = FloatingSearchBarController();
  DateTime? currentBackPressTime = DateTime.now();
  List<Site> _sites = [];
  List<String> _autosuggest = [];
  final List<Site> _tabs = [];
  final List<GalleryView> _gallerys = [];
  int _currentSiteId = 920;
  int _currentTabIndex = 0;

  Future<void> _initialize() async {
    // final sites = await RuleLoader.loadFormDirectory(await Config.ruleDir);
    // sites.forEachIndexed(
    //     (i, element) => print('$i: [${element.id}]${element.name}'));
    await _checkUpdate();
    setState(() {
      // _sites = sites;
      _sites = RuleLoader.sites.values.toList();
      _currentSiteId = _currentSiteId < 0 ? _sites[0].id! : _currentSiteId;
      _tabs.add(_currentSite!);
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

  GalleryView? get _currentTab {
    return _gallerys.isNotEmpty ? _gallerys[_currentTabIndex] : null;
  }

  Future<void> _checkUpdate() async {
    final ruleDir = (await Config.ruleDir);
    await RuleLoader.loadFormDirectory(ruleDir);
    if (RuleLoader.sites.isEmpty) {
      await _updateSubscribe(ruleDir);
    }
  }

  Future<void> _updateSubscribe(Directory dir) async {
    final savePath = dir.join('rules.zip').path;
    await Http.client().download('https://hlo.li/static/rules.zip', savePath);
    await RuleLoader.loadFormDirectory(dir);
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
    if (currentBackPressTime == null || now.difference(currentBackPressTime!) > const Duration(seconds: 2)) {
      currentBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('再按一次退出')));
      return Future.value(false);
    }
    return Future.value(true);
  }

  Widget buildDrawer() {
    return Drawer(
        child: ListView(padding: EdgeInsets.zero, children: [
      Stack(children: [
        CachedNetworkImage(
          imageUrl: 'https://cdn.jsdelivr.net/gh/nyarray/LoliHost/images/94d6d0e7be187770e5d538539d95a12a.jpeg',
          fit: BoxFit.cover,
          height: 256,
        ),
        Positioned.fill(
          child: Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  gradient: LinearGradient(begin: FractionalOffset.topCenter, end: FractionalOffset.bottomCenter, colors: [
                    Colors.grey.withOpacity(0.0),
                    Colors.black45,
                  ], stops: const [
                    0.0,
                    1.0
                  ])),
              padding: const EdgeInsets.all(8),
              alignment: Alignment.bottomLeft,
              child: const Text('ポトフちゃんとワトラちゃんがすごくかわいいです！', style: TextStyle(color: Colors.white, fontSize: 18))),
        ),
      ]),
      Container(height: 8),
      ListTile(
          title: const Text('主页'),
          selected: true,
          selectedTileColor: const Color.fromRGBO(0, 127, 127, .2),
          onTap: () {},
          iconColor: Colors.teal,
          leading: const Icon(Icons.home)),
      ListTile(
          title: const Text('订阅'),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (ctx) => const SubscribeView()));
          },
          iconColor: Colors.black87,
          leading: const Icon(Icons.collections_bookmark)),
      ListTile(title: const Text('下载'), onTap: () {}, iconColor: Colors.black87, leading: const Icon(Icons.download)),
      ListTile(
          title: const Text('设置'),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (ctx) => const SettingsView()));
          },
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
            imageUrl: 'https://cdn.jsdelivr.net/gh/nyarray/LoliHost/images/7c4f1d7ea2dadd3ca835b9b2b9219681.webp',
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
                              setState(() {
                                _currentSiteId = _sites[index].id!;
                                _tabs.add(_currentSite!);
                                // _carouselController
                                //     .animateToPage(_tabs.length - 1);
                                globalKey.currentState?.closeEndDrawer();
                              });
                              setState(() {});
                            },
                            child: ListTile(
                              leading: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CachedNetworkImage(
                                    imageUrl: _sites[index].icon ?? '',
                                    fit: BoxFit.cover,
                                    errorWidget: (ctx, url, error) => const Icon(Icons.image_not_supported, size: 32),
                                  )),
                              title: Text(
                                _sites[index].name ?? '',
                                style: const TextStyle(
                                  fontFamily: Config.uiFontFamily,
                                  fontSize: 18,
                                ),
                                textAlign: TextAlign.start,
                              ),
                              subtitle: Text(
                                _sites[index].details ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14, color: Colors.black26),
                              ),
                              trailing: Icon(_sites[index].type == 'comic'
                                  ? Icons.photo_library
                                  : _sites[index].type == 'image'
                                      ? Icons.image
                                      : _sites[index].type == 'video'
                                          ? Icons.video_collection
                                          : Icons.quiz,
                              color: Theme.of(context).primaryColor),
                            )));
                  })),
        ])));
  }

  Future<ImageInfo> getImageInfo(ImageProvider image) async {
    final c = Completer<ImageInfo>();
    image.resolve(const ImageConfiguration()).addListener(ImageStreamListener((ImageInfo i, bool _) => c.complete(i)));
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
                  child: DynamicTabView(
                    // initPosition: _tabs.isNotEmpty ? _tabs.length - 1 : 0,
                    onPositionChange: (int index) {
                      print('onPositionChangeonPositionChangeonPositionChangeonPositionChangeonPositionChangeonPositionChange');
                      setState(() => _currentTabIndex = index);
                    },
                    itemCount: _tabs.length,
                    isScrollToNewTab: true,
                    pageBuilder: (BuildContext context, int index) {
                      while (_gallerys.length <= index) {
                        _gallerys.add(GalleryView(site: _tabs[index]));
                      }
                      return _gallerys[index];
                    },
                    onScroll: (double value) {},
                    tabBuilder: (BuildContext context, int index) {
                      return InkWell(
                        onLongPress: () {
                          if (_tabs.length > 1) {
                            setState(() => _tabs.removeAt(index));
                          } else {
                            Fluttertoast.showToast(msg: '您不能删除最后一个标签页');
                          }
                        },
                          child:  Tab(
                          iconMargin: EdgeInsets.zero,
                          height: 48,
                          icon: SizedBox(
                              width: 24,
                              height: 24,
                              child: CachedNetworkImage(
                                imageUrl: _tabs[index].icon ?? '',
                                fit: BoxFit.contain,
                              )),
                          text: _tabs[index].name ?? ''));
                    },
                  )),
              buildFloatingSearchBar(),
            ],
          )),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Container(
          margin: const EdgeInsets.only(bottom: 48),
          child: FloatingActionButton(
            onPressed: () =>
                _currentTab?.controller.animateTo!(0, duration: const Duration(milliseconds: 1000), curve: Curves.ease),
            //globalKey.currentState?.openEndDrawer(),
            tooltip: 'Top',
            child: const Icon(Icons.arrow_upward),
          )),
    );
  }

  Widget buildFloatingSearchBar() {
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return FloatingSearchBar(
        title: Text(
          StringUtil.value(_currentTab?.controller.keywords, 'Search...'),
          style: TextStyle(
              fontFamily: Config.uiFontFamily,
              fontSize: 16,
              color: _currentTab?.controller.keywords == null ? Colors.black26 : Colors.black87),
        ),
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
        hintStyle: const TextStyle(fontFamily: Config.uiFontFamily, fontSize: 16, color: Colors.black26),
        queryStyle: const TextStyle(fontFamily: Config.uiFontFamily, fontSize: 16),
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
        // transition: SlideFadeFloatingSearchBarTransition(),
        leadingActions: [
          FloatingSearchBarAction.hamburgerToBack(),
          FloatingSearchBarAction(
              showIfOpened: true,
              child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CachedNetworkImage(
                      imageUrl: _currentTab?.site.icon ?? '',
                      errorWidget: (ctx, url, error) {
                        return Text(
                          _currentSite?.name?.substring(0, 1) ?? '?',
                          style: const TextStyle(fontFamily: Config.uiFontFamily, fontSize: 18, color: Colors.teal),
                        );
                      }))),
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
          _currentTab?.controller.search!(query);
          _floatingSearchBarController.close();
        },
        builder: (context, transition) => Material(
              color: Colors.white,
              elevation: 4.0,
              borderRadius: BorderRadius.circular(4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _autosuggest
                    .map((query) => ListTile(
                        leading: const Icon(Icons.search),
                        onTap: () {
                          _currentTab?.controller.search!(query);
                          _floatingSearchBarController.query = query;
                          _floatingSearchBarController.close();
                        },
                        title: Text(
                          query,
                          style: const TextStyle(fontFamily: Config.uiFontFamily, fontSize: 14),
                        )))
                    .toList(),
              ),
            ));
  }
}
