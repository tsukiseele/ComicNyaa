import 'dart:async';
import 'package:collection/collection.dart';
import 'package:comic_nyaa/data/subscribe_holder.dart';
import 'package:comic_nyaa/library/mio/core/mio_loader.dart';
import 'package:comic_nyaa/library/mio/model/base.dart';
import 'package:comic_nyaa/views/settings_view.dart';
import 'package:comic_nyaa/views/subscribe_view.dart';
import 'package:comic_nyaa/widget/nyaa_tab_view.dart';
import 'package:comic_nyaa/widget/simple_network_image.dart';
import 'package:dio/dio.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

import 'package:comic_nyaa/library/mio/model/site.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';

import '../app/global.dart';
import '../utils/string_extensions.dart';
import '../widget/marquee_widget.dart';
import 'pages/gallery_view.dart';

class MainView extends StatefulWidget {
  const MainView({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> with TickerProviderStateMixin {
  final globalKey = GlobalKey<ScaffoldState>();
  final FloatingSearchBarController _floatingSearchBarController =
      FloatingSearchBarController();
  final List<GalleryView> _gallerys = [];
  ScrollController? _galleryScrollController;
  List<Site> _sites = [];
  List<String> _autosuggest = [];
  int _currentTabIndex = 0;
  DateTime? currentBackPressTime = DateTime.now();
  int _lastScrollPosition = 0;

  final colorList = [
    Colors.blue[100],
    Colors.green[100],
    Colors.purple[100],
    Colors.amber[100],
    Colors.pink[100]
  ];
  final textColorList = [
    Colors.blue[300],
    Colors.green[300],
    Colors.purple[300],
    Colors.amber[300],
    Colors.pink[300]
  ];

  Future<void> _initialize() async {
    await _checkUpdate();
    setState(() {
      _sites = RuleLoader.sites.values.toList();
      // 打开默认标签
      addTab(_sites.firstWhereOrNull((site) => site.id == 920) ?? _sites[0]);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // _galleryScrollController = _currentTab?.controller.scrollController;
          //   if (_galleryScrollController == null) return;
          //   _galleryScrollController!.removeListener(onGalleryScroll);
          //   _galleryScrollController!.addListener(onGalleryScroll);
        }
      });
    });
  }

  Future<void> _checkUpdate() async {
    final ruleDir = (await Config.ruleDir);
    await RuleLoader.loadFormDirectory(ruleDir);
    if (RuleLoader.sites.isEmpty) {
      await SubscribeHolder().updateAllSubscribe();
    }
  }

  @override
  void initState() {
    _initialize();
    super.initState();
  }

  GalleryView? get _currentTab {
    return _gallerys.isNotEmpty ? _gallerys[_currentTabIndex] : null;
  }

  void addTab(Site site) {
    _gallerys.add(GalleryView(site: site));
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _currentTabIndex = _gallerys.length - 1;
    // });
  }

  void removeTab(int index) {
    // final temp = _gallerys[index];
    // _gallerys.removeAt(index);
    // _gallerys.add(temp);
    setState(() {
      print('REMOVE::::: ${_gallerys[index].site.name}');
      // try {
      //   _gallerys[index].controller.scrollController?.dispose();
      // } catch (e) {
      //   print(e);
      // }
      _gallerys.removeAt(index);
      if (_currentTabIndex > _gallerys.length - 1) {
        _currentTabIndex = _gallerys.length - 1;
      }
    });
  }

  onGalleryScroll() {
    if (_galleryScrollController == null) return;
    // if (_galleryScrollController!.positions.isEmpty) _galleryScrollController!.dispose();
    if (_galleryScrollController!.position.pixels < 128) {
      _floatingSearchBarController.isHidden
          ? _floatingSearchBarController.show()
          : null;
    } else if (_galleryScrollController!.position.pixels >
        _lastScrollPosition + 64) {
      _lastScrollPosition = _galleryScrollController!.position.pixels.toInt();
      _floatingSearchBarController.isVisible
          ? _floatingSearchBarController.hide()
          : null;
    } else if (_galleryScrollController!.position.pixels <
        _lastScrollPosition - 64) {
      _lastScrollPosition = _galleryScrollController!.position.pixels.toInt();
      _floatingSearchBarController.isHidden
          ? _floatingSearchBarController.show()
          : null;
    }
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
              _gallerys.isNotEmpty
                  ? NyaaTabView(
                      position: _currentTabIndex,
                      onPositionChange: (int index) {
                        setState(() => _currentTabIndex = index);
                        // Remove old scroll listener
                        for (var item in _gallerys) {
                          item.controller.scrollController?.removeListener(onGalleryScroll);
                        }
                        // Add new scroll listener
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            _galleryScrollController = _currentTab?.controller.scrollController;
                            if (_galleryScrollController == null) return;
                            onGalleryScroll();
                            _galleryScrollController!.addListener(onGalleryScroll);
                          }
                        });
                      },
                      onScroll: (double value) {},
                      itemCount: _gallerys.length,
                      isScrollToNewTab: true,
                      color: colorList[_currentTabIndex % colorList.length],
                      indicator: const BoxDecoration(
                          color: Colors.white70,
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 8)
                          ],
                          // color: colorList[_currentTabIndex % colorList.length]
                          //     ?.withOpacity(.6),
                          borderRadius: BorderRadius.all(Radius.circular(20))
                          // borderRadius: BorderRadius.only(bottomLeft:Radius.circular(12), bottomRight: Radius.circular(12)),
                          ),
                      pageBuilder: (BuildContext context, int index) =>
                          _gallerys[index],
                      tabBuilder: (BuildContext context, int index) {
                        return InkWell(
                            onLongPress: () {
                              if (_gallerys.length > 1) {
                                setState(() => removeTab(index));
                              } else {
                                Fluttertoast.showToast(msg: '您不能删除最后一个标签页');
                              }
                            },
                            onTap: () {
                              setState(() => _currentTabIndex = index);
                            },
                            child: AnimatedSize(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.ease,
                                child: Row(children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    padding: EdgeInsets.only(
                                        top: 8,
                                        bottom: 8,
                                        right:
                                            _currentTabIndex == index ? 8 : 0),
                                    child: SimpleNetworkImage(
                                        _gallerys[index].site.icon ?? '',
                                        fit: BoxFit.contain,
                                        clearMemoryCacheIfFailed: false),
                                    // child: CachedNetworkImage(
                                    //   imageUrl:
                                    //       _gallerys[index].site.icon ?? '',
                                    //   fit: BoxFit.contain,
                                    // )
                                  ),
                                  _currentTabIndex == index
                                      ? SizedBox(
                                          width: _currentTabIndex == index
                                              ? 96.0
                                              : null,
                                          child: MarqueeWidget(
                                              direction: Axis.horizontal,
                                              child: Text(
                                                  _gallerys[index].site.name ??
                                                      'unknown',
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.black87
                                                      // color: textColorList[
                                                      //     _currentTabIndex %
                                                      //         colorList
                                                      //             .length]
                                                      ))))
                                      : Container()
                                ])));
                      })
                  : Container(),
              buildFloatingSearchBar(),
            ],
          )),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Container(
          margin: const EdgeInsets.only(bottom: 48),
          child: FloatingActionButton(
            onPressed: () => _currentTab?.controller.animateTo!(0,
                duration: const Duration(milliseconds: 1000),
                curve: Curves.ease),
            tooltip: 'Top',
            child: const Icon(Icons.arrow_upward),
          )),
    );
  }

  Widget buildFloatingSearchBar() {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return FloatingSearchBar(
        title: Text(
          StringUtil.value(_currentTab?.controller.keywords, 'Search...'),
          style: TextStyle(
              fontFamily: Config.uiFontFamily,
              fontSize: 16,
              color: isEmpty(_currentTab?.controller.keywords == null)
                  ? Colors.black26
                  : Colors.black87),
        ),
        controller: _floatingSearchBarController,
        automaticallyImplyDrawerHamburger: false,
        automaticallyImplyBackButton: false,
        hint: 'Search...',
        scrollPadding: const EdgeInsets.only(top: 8, bottom: 8),
        // implicitDuration: const Duration(milliseconds: 250),
        transitionDuration: const Duration(milliseconds: 200),
        transitionCurve: Curves.easeInOut,
        // physics: const BouncingScrollPhysics(),
        axisAlignment: isPortrait ? 0.0 : -1.0,
        openAxisAlignment: 0.0,
        width: isPortrait ? 600 : 500,
        debounceDelay: const Duration(milliseconds: 500),
        // clearQueryOnClose: false,
        hintStyle: const TextStyle(
            fontFamily: Config.uiFontFamily,
            fontSize: 16,
            color: Colors.black26),
        queryStyle:
            const TextStyle(fontFamily: Config.uiFontFamily, fontSize: 16),
        onQueryChanged: (query) async {
          final value = await Dio().get(
              'https://danbooru.donmai.us/autocomplete.json?search[query]=$query&search[type]=tag_query&limit=10');
          final result = List<Map<String, dynamic>>.from(value.data);
          setState(() {
            _autosuggest =
                result.map((item) => item['value'] as String).toList();
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
                  child: SimpleNetworkImage(_currentTab?.site.icon ?? '',
                      error: Text(
                        _currentTab?.site.name?.substring(0, 1) ?? '?',
                        style: const TextStyle(
                            fontFamily: Config.uiFontFamily,
                            fontSize: 18,
                            color: Colors.teal),
                      )))),
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
                          style: const TextStyle(
                              fontFamily: Config.uiFontFamily, fontSize: 14),
                        )))
                    .toList(),
              ),
            ));
  }

  Widget buildDrawer() {
    return Drawer(
        child: ListView(padding: EdgeInsets.zero, children: [
      Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Stack(children: [
            ExtendedImage.network(
              'https://cdn.jsdelivr.net/gh/nyarray/LoliHost/images/94d6d0e7be187770e5d538539d95a12a.jpeg',
              fit: BoxFit.cover,
              width: double.maxFinite,
              height: 160 + kToolbarHeight,
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
                  child: Text(
                      "Os iustī meditabitur sapientiam, Et lingua eius loquetur iudicium.",
                      // "ポトフちゃんとワトラちゃんがすごくかわいいです！",
                      style: TextStyle(color: Colors.teal[200], fontSize: 18,
                          // fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(color: Colors.teal[100]!, blurRadius: 8)
                          ]))),
              // child: const Text('ポトフちゃんとワトラちゃんがすごくかわいいです！',
              //     style: TextStyle(color: Colors.white, fontSize: 16))),
            ),
          ])),
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
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (ctx) => const SettingsView()));
          },
          iconColor: Colors.black87,
          leading: const Icon(Icons.tune))
    ]));
  }

  Widget buildEndDrawer() {
    return Drawer(
      // width: 256,
      elevation: 8,
      child: ListView.builder(
          padding: const EdgeInsets.only(top: 8),
          itemCount: _sites.length + 1,
          itemBuilder: (ctx, i) {
            final index = i - 1;
            if (index < 0) {
              return const SimpleNetworkImage(
                    'https://cdn.jsdelivr.net/gh/nyarray/LoliHost/images/7c4f1d7ea2dadd3ca835b9b2b9219681.webp',
                fit: BoxFit.cover,
                height: 120 + kToolbarHeight,
              );
            }
            return Material(
                child: InkWell(
                    onTap: () {
                      setState(() {
                        // _tabs.add(_sites[index]);
                        addTab(_sites[index]);
                        globalKey.currentState?.closeEndDrawer();
                      });
                      setState(() {});
                    },
                    child: ListTile(
                      leading: SizedBox(
                          width: 32,
                          height: 32,
                          child: SimpleNetworkImage(_sites[index].icon ?? '',
                            fit: BoxFit.cover,
                            error: const Icon(Icons.image_not_supported, size: 32),
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
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black26),
                      ),
                      trailing: Icon(
                          _sites[index].type == 'comic'
                              ? Icons.photo_library
                              : _sites[index].type == 'image'
                                  ? Icons.image
                                  : _sites[index].type == 'video'
                                      ? Icons.video_collection
                                      : Icons.quiz,
                          color: Theme.of(context).primaryColor),
                    )));
          }),
    );
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
}
