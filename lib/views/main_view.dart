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
import 'dart:isolate';
import 'package:comic_nyaa/data/tags/tags_autosuggest.dart';
import 'package:comic_nyaa/library/mio/label/danbooru_autosuggest.dart';
import 'package:comic_nyaa/library/mio/label/yandere_autosuggest.dart';
import 'package:comic_nyaa/utils/flutter_utils.dart';
import 'package:comic_nyaa/utils/string_extensions.dart';
import 'package:comic_nyaa/widget/back_control.dart';
import 'package:comic_nyaa/views/drawer/nyaa_end_drawer.dart';
import 'package:comic_nyaa/widget/empty_data.dart';
import 'package:comic_nyaa/widget/nyaa_tag_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';
import 'package:comic_nyaa/library/http/http.dart';
import 'package:comic_nyaa/library/mio/model/site.dart';
import 'package:comic_nyaa/library/mio/core/site_manager.dart';
import 'package:comic_nyaa/widget/nyaa_tab_view.dart';
import 'package:comic_nyaa/widget/simple_network_image.dart';
import 'package:comic_nyaa/app/app_config.dart';
import 'package:comic_nyaa/data/download/nyaa_download_manager.dart';
import 'package:comic_nyaa/models/typed_model.dart';
import 'package:comic_nyaa/widget/marquee_widget.dart';
import 'package:comic_nyaa/views/pages/gallery_view.dart';

import 'package:comic_nyaa/data/subscribe/subscribe_manager.dart';
import 'package:comic_nyaa/views/drawer/nyaa_drawer.dart';
import 'package:tuple/tuple.dart';

import '../library/mio/model/tag.dart';

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
  List<Tag> _autosuggest = [];
  int _currentTabIndex = 0;
  int _lastScrollPosition = 0;
  String _keywords = '';

  final _tabColors = [
    Colors.teal,
    Colors.amber,
    Colors.blue,
    Colors.purple,
    Colors.green,
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
    final ruleDir = (await AppConfig.ruleDir);
    await SiteManager.loadFromDirectory(ruleDir);
    if (SiteManager.sites.isEmpty) {
      await (await SubscribeManager.instance).updateAllSubscribe();
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
        _galleryScrollController = _currentTab?.controller.scrollController;
        if (_galleryScrollController == null) return;
        _onGalleryScroll();
        _galleryScrollController!.addListener(_onGalleryScroll);
      }
    });
  }

  void _onGalleryScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_galleryScrollController == null ||
          _galleryScrollController?.positions.isNotEmpty != true) return;
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
    });
  }

  void _listenGalleryItemSelected() {
    _currentTab?.controller.onItemSelect = _onGalleryItemSelected;
  }

  void _onGalleryItemSelected(Map<int, TypedModel> selects) {
    setState(() {});
  }

  void _onSearch(String query) async {
    _floatingSearchBarController.close();
    _currentTab?.controller.search?.call(query);
    setState(() => _floatingSearchBarController.query = query);
  }

  String _onSuggestQuery(String query, [String? suggest]) {
    print('MainView::_onSuggestQuery ==> query: $query, suggest: $suggest');
    if (suggest != null) {
      int lastWordIndex = query.lastIndexOf(' ');
      lastWordIndex = lastWordIndex > 0 ? lastWordIndex : 0;
      query = query.substring(0, query.lastIndexOf(' ') + 1) + suggest;
    }
    return query;
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
          ? BackControl(child: view, onBack: () => !_onBackPress())
          : view,
    );
  }

  Widget _buildEndDrawer() {
    return NyaaEndDrawer(
      sites: _sites,
      onItemTap: (site) {
        setState(() => _addTab(site));
        globalKey.currentState?.closeEndDrawer();
      },
    );
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
    final color = _getTabColor(_gallerys.length);
    return GalleryView(
      site: site,
      heroKey: _gallerys.length.toString(),
      color: color,
      empty: EmptyData(
        text: '无可用数据',
        color: color,
        textColor: color,
      ),
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

  // static _queryAutosuggest(Tuple3<SendPort, String, String> message) async {
  //   final autosuggest = await YandereAutosuggest.instance
  //       .queryAutoSuggest(message.item2, message.item3);
  //   message.item1.send(
  //       autosuggest.length > 20 ? autosuggest.sublist(0, 20) : autosuggest);
  // }

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
            fontFamily: AppConfig.uiFontFamily,
            fontSize: 16,
            color: Colors.black26),
        queryStyle:
            const TextStyle(fontFamily: AppConfig.uiFontFamily, fontSize: 16),
        onQueryChanged: (query) async {
          _keywords = query;
          const limit = 20;
          final lastWordIndex = query.lastIndexOf(' ');
          final word =
              query.substring(lastWordIndex > 0 ? lastWordIndex : 0).trim();
          // print('QUERYYYYY: $word');
          final autosuggest = await SearchAutoSuggest.instance
              .queryAutoSuggest(word, limit: limit);
          // print('RESULT:: $autosuggest');
          setState(() => _autosuggest = autosuggest);
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
                            fontFamily: AppConfig.uiFontFamily,
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
                    .map(
                      (suggest) => ListTile(
                        minLeadingWidth: 16,
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        onTap: () => _onSearch(
                            _onSuggestQuery(_keywords, suggest.label)),
                        leading: const Icon(
                          Icons.search,
                        ),
                        title: Text(
                          suggest.label,
                          style: TextStyle(
                              fontFamily: AppConfig.uiFontFamily,
                              fontSize: 16,
                              color: suggest.type != null
                                  ? ColorUtil.fromHex(suggest.type!.color)
                                  : null),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle:
                            suggest.alias != null && suggest.alias!.isNotEmpty
                                ? MarqueeWidget(
                                    child: Text(
                                    suggest.alias!.replaceAll(',', ', '),
                                    style: const TextStyle(
                                        fontFamily: AppConfig.uiFontFamily,
                                        fontSize: 14,
                                        color: Colors.black54),
                                  ))
                                : null,
                        trailing:
                            Row(mainAxisSize: MainAxisSize.min, children: [
                          NyaaTagItem(
                              text: suggest.type?.name ?? '',
                              textStyle: const TextStyle(
                                  fontSize: 12, color: Colors.white),
                              color: suggest.type != null
                                  ? ColorUtil.fromHex(suggest.type!.color)
                                  : null,
                              isRounded: true),
                          InkWell(
                              onTap: () {
                                _floatingSearchBarController.query =
                                    _onSuggestQuery(
                                        _floatingSearchBarController.query,
                                        suggest.label);
                              },
                              child: const Icon(
                                Icons.add,
                                size: 32,
                              )),
                        ]),
                      ),
                    )
                    .toList(),
              ),
            ));
  }

  bool _onBackPress() {
    final ScaffoldState state = globalKey.currentState!;
    if (_floatingSearchBarController.isOpen) {
      _floatingSearchBarController.close();
      return true;
    }
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
