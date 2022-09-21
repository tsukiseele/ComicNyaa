/*
 * Copyright (C) 2022. TsukiSeele
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:async';
import 'dart:convert';
import 'package:comic_nyaa/widget/back_control.dart';
import 'package:comic_nyaa/views/drawer/nyaa_end_drawer.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:collection/collection.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';
import 'package:comic_nyaa/library/http/http.dart';
import 'package:comic_nyaa/library/mio/model/site.dart';
import 'package:comic_nyaa/library/mio/core/site_manager.dart';
import 'package:comic_nyaa/data/subscribe_provider.dart';
import 'package:comic_nyaa/widget/nyaa_tab_view.dart';
import 'package:comic_nyaa/widget/simple_network_image.dart';
import 'package:comic_nyaa/app/config.dart';
import 'package:comic_nyaa/data/download/nyaa_download_manager.dart';
import 'package:comic_nyaa/models/typed_model.dart';
import 'package:comic_nyaa/widget/marquee_widget.dart';
import 'package:comic_nyaa/views/pages/gallery_view.dart';

import '../data/widget_cache_provider.dart';
import 'drawer/nyaa_drawer.dart';

class MainView extends StatefulWidget {
  const MainView(
      {Key? key, this.site, this.keywords, this.enableBackControl = false})
      : super(key: key);
  final Site? site;
  final String? keywords;
  final bool enableBackControl;

  @override
  State<MainView> createState() => MainViewState();
}

class MainViewState extends State<MainView> with TickerProviderStateMixin {
  final globalKey = GlobalKey<ScaffoldState>();
  final FloatingSearchBarController _floatingSearchBarController =
      FloatingSearchBarController();
  final List<GalleryView> _gallerys = [];
  ScrollController? _galleryScrollController;
  List<Site> _sites = [];
  List<String> _autosuggest = [];
  int _currentTabIndex = 0;
  int _lastScrollPosition = 0;
  String _keywords = '';

  final _tabColors = [
    Colors.teal,
    Colors.blue,
    Colors.purple,
    Colors.green,
    Colors.amber,
    Colors.pink,
  ];

  MaterialColor _getTabColor(int index) {
    return _tabColors[index % _tabColors.length];
  }

  Future<void> _initialize() async {
    await _checkUpdate();
    setState(() {
      _sites = SiteManager.sites.values.toList();
      // 打开默认标签
      if (widget.site != null) {
        _addTab(widget.site!);
      } else {
        _addTab(_sites.firstWhereOrNull((site) => site.id == 920) ?? _sites[0]);
      }

      _listenGalleryScroll();
      _currentTab?.controller.onItemSelect = _onGalleryItemSelected;
    });
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (widget.keywords != null) {
        _onSearch(widget.keywords!);
      }
    });
  }

  Future<void> _checkUpdate() async {
    final ruleDir = (await Config.ruleDir);
    await SiteManager.loadFromDirectory(ruleDir);
    if (SiteManager.sites.isEmpty) {
      await SubscribeProvider().updateAllSubscribe();
    }
  }

  Future<void> downloadSelections() async {
    List<TypedModel> items = _currentTab!.controller.selects.values.toList();
    Fluttertoast.showToast(msg: '${items.length}个任务已添加');

    (await NyaaDownloadManager.instance).addAll(items);
    setState(() {
      _currentTab?.controller.clearSelection();
    });
  }

  @override
  void initState() {
    _initialize();
    super.initState();
  }

  GalleryView? get _currentTab {
    return _gallerys.isNotEmpty ? _gallerys[_currentTabIndex] : null;
  }

  void _addTab(Site site) {
    _gallerys.add(_buildTab(site));
  }

  void _removeTab(int index) {
    setState(() {
      _gallerys.removeAt(index);
      if (_currentTabIndex > _gallerys.length - 1) {
        _currentTabIndex = _gallerys.length - 1;
      }
    });
  }

  void _listenGalleryScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Remove old scroll listener
        for (var item in _gallerys) {
          item.controller.scrollController?.removeListener(_onGalleryScroll);
        }
        // Add new scroll listener
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _galleryScrollController = _currentTab?.controller.scrollController;
            if (_galleryScrollController == null) return;
            _onGalleryScroll();
            _galleryScrollController!.addListener(_onGalleryScroll);
          }
        });
      }
    });
  }

  void _onGalleryScroll() {
    if (_galleryScrollController == null) return;
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

  void _listenGalleryItemSelected() {
    _currentTab?.controller.onItemSelect = _onGalleryItemSelected;
  }

  void _onGalleryItemSelected(Map<int, TypedModel> selects) {
    setState(() {});
  }

  void _onSearch(String query, [String? suggest]) async {
    print('MainView::onSearch ==> query: $query, suggest: $suggest');
    if (suggest != null) {
      int lastWordIndex = query.lastIndexOf(' ');
      lastWordIndex = lastWordIndex > 0 ? lastWordIndex : 0;
      query = query.substring(0, query.lastIndexOf(' ') + 1) + suggest;
    }
    _floatingSearchBarController.close();
    _currentTab?.controller.search?.call(query);
    setState(() => _floatingSearchBarController.query = query);
  }

  @override
  Widget build(BuildContext context) {
    final view = _buildMain();
    return Scaffold(
      key: globalKey,
      drawerEdgeDragWidth: 64,
      drawerEnableOpenDragGesture: true,
      endDrawerEnableOpenDragGesture: true,
      resizeToAvoidBottomInset: false,
      drawer: const NyaaDrawer(),
      endDrawer: _buildEndDrawer(),
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
      body: widget.enableBackControl
          ? BackControl(child: view, onBack: () => !_closeDrawer())
          : view,
    );
  }

  Widget _buildEndDrawer() {
    return  NyaaEndDrawer(
      sites: _sites,
      onItemTap: (site) {
        // print('DRAWER WRITE CACHE::: $key');
        setState(() => _addTab(site));
        globalKey.currentState?.closeEndDrawer();
      },
    );
    const key = 'endDrawer';
    Widget? drawer = WidgetCacheProvider().get(key);
    print('DRAWER READ CACHE::: $key');
    if (drawer == null || _sites.isEmpty) {
      drawer = NyaaEndDrawer(
        sites: _sites,
        onItemTap: (site) {
          // print('DRAWER WRITE CACHE::: $key');
          setState(() => _addTab(site));
          globalKey.currentState?.closeEndDrawer();
        },
      );
      WidgetCacheProvider().put(key, drawer);
    }
    return drawer;

  }

  Widget _buildMain() {
    return Stack(
      fit: StackFit.expand,
      children: [
        _gallerys.isNotEmpty
            ? NyaaTabView(
                position: _currentTabIndex,
                onPositionChange: (int index) {
                  setState(() => _currentTabIndex = index);
                  _listenGalleryScroll();
                  _listenGalleryItemSelected();
                  _floatingSearchBarController.query =
                      _currentTab?.controller.keywords ?? '';
                },
                onScroll: (double value) {},
                itemCount: _gallerys.length,
                isScrollToNewTab: true,
                color: _getTabColor(_currentTabIndex)[100],
                tabBarColor: _getTabColor(_currentTabIndex)[200],
                elevation: 8,
                indicator: const BoxDecoration(
                    color: Colors.white70,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 8)
                    ],
                    borderRadius: BorderRadius.all(Radius.circular(20))),
                pageBuilder: (BuildContext context, int index) =>
                    _gallerys[index],
                tabBuilder: (BuildContext context, int index) {
                  return InkWell(
                      onLongPress: () {
                        if (_gallerys.length > 1) {
                          setState(() => _removeTab(index));
                        } else {
                          Fluttertoast.showToast(msg: '您不能删除最后一个标签页');
                        }
                      },
                      onTap: () {
                        setState(() => _currentTabIndex = index);
                      },
                      child: AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          child: Row(children: [
                            Container(
                              width: 40,
                              height: 40,
                              padding: EdgeInsets.only(
                                  top: 8,
                                  bottom: 8,
                                  right: _currentTabIndex == index ? 8 : 0),
                              child: SimpleNetworkImage(
                                  _gallerys[index].site.icon ?? '',
                                  fit: BoxFit.contain,
                                  clearMemoryCacheIfFailed: false),
                            ),
                            _currentTabIndex == index
                                ? SizedBox(
                                    width:
                                        _currentTabIndex == index ? 96.0 : null,
                                    child: MarqueeWidget(
                                        direction: Axis.horizontal,
                                        child: Text(
                                            _gallerys[index].site.name ??
                                                'unknown',
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.black87))))
                                : Container()
                          ])));
                })
            : Container(),
        _buildFloatingSearchBar(),
      ],
    );
  }

  GalleryView _buildTab(Site site) {
    return GalleryView(
      site: site,
      heroKey: _gallerys.length.toString(),
      color: _getTabColor(_gallerys.length),
    );
  }

  Widget _buildFab() {
    return Container(
        margin: const EdgeInsets.only(bottom: 48),
        child: _currentTab?.controller.selects.isEmpty == true
            ? FloatingActionButton(
                backgroundColor: _getTabColor(_currentTabIndex),
                onPressed: () => _currentTab?.controller.scrollController
                    ?.animateTo(0,
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.ease),
                tooltip: 'Top',
                child: const Icon(Icons.arrow_upward),
              )
            : FloatingActionButton(
                backgroundColor: _getTabColor(_currentTabIndex),
                onPressed: () {
                  downloadSelections();
                },
                tooltip: 'Download',
                child: const Icon(Icons.download),
              ));
  }

  Widget _buildFloatingSearchBar() {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    return FloatingSearchBar(
        controller: _floatingSearchBarController,
        automaticallyImplyDrawerHamburger: false,
        automaticallyImplyBackButton: false,
        hint: 'Search...',
        scrollPadding: const EdgeInsets.only(top: 8, bottom: 8),
        // implicitDuration: const Duration(milliseconds: 250),
        transitionDuration: const Duration(milliseconds: 200),
        debounceDelay: const Duration(milliseconds: 500),
        transitionCurve: Curves.easeInOut,
        // physics: const BouncingScrollPhysics(),
        axisAlignment: isPortrait ? 0.0 : -1.0,
        openAxisAlignment: 0.0,
        width: isPortrait ? 600 : 500,
        clearQueryOnClose: false,
        closeOnBackdropTap: true,
        hintStyle: const TextStyle(
            fontFamily: Config.uiFontFamily,
            fontSize: 16,
            color: Colors.black26),
        queryStyle:
            const TextStyle(fontFamily: Config.uiFontFamily, fontSize: 16),
        onQueryChanged: (query) async {
          _keywords = _floatingSearchBarController.query;
          final lastWordIndex = query.lastIndexOf(' ');
          final word = query.substring(lastWordIndex > 0 ? lastWordIndex : 0);
          final response = await Http.client.get(Uri.parse(
              'https://danbooru.donmai.us/autocomplete.json?search[query]=$word&search[type]=tag_query&limit=10'));
          final result =
              List<Map<String, dynamic>>.from(jsonDecode(response.body));
          setState(() {
            _autosuggest =
                result.map((item) => item['value'] as String).toList();
            print('_autosuggest: $_autosuggest');
          });
        },
        transition: CircularFloatingSearchBarTransition(),
        leadingActions: [
          FloatingSearchBarAction.hamburgerToBack(),
          FloatingSearchBarAction(
              showIfOpened: true,
              child: SizedBox(
                  width: 24,
                  height: 24,
                  child: SimpleNetworkImage(_currentTab?.site.icon ?? '',
                      error: Text(
                        _currentTab?.site.name?.substring(0, 1) ?? '',
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
              icon: const Icon(Icons.send_time_extension),
              onPressed: () => globalKey.currentState?.openEndDrawer(),
            ),
          ),
          FloatingSearchBarAction.searchToClear(
            showIfClosed: false,
          ),
        ],
        onSubmitted: (query) => _onSearch(query),
        onFocusChanged: (isFocus) {
          if (!isFocus) {
            if (_floatingSearchBarController.query !=
                _currentTab?.controller.keywords) {
              setState(() => _floatingSearchBarController.query =
                  _currentTab?.controller.keywords ?? '');
            }
          }
        },
        builder: (context, transition) => Material(
              color: Colors.white,
              elevation: 4.0,
              borderRadius: BorderRadius.circular(4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _autosuggest
                    .map((suggest) => ListTile(
                        leading: const Icon(Icons.search),
                        onTap: () => _onSearch(_keywords, suggest),
                        title: Text(
                          suggest,
                          style: const TextStyle(
                              fontFamily: Config.uiFontFamily, fontSize: 14),
                        )))
                    .toList(),
              ),
            ));
  }

  bool _closeDrawer() {
    final ScaffoldState state = globalKey.currentState!;
    if (state.isDrawerOpen == true) {
      state.closeDrawer();
      return true;
    }
    if (state.isEndDrawerOpen == true) {
      state.closeEndDrawer();
      return true;
    }
    return false;
  }
}
