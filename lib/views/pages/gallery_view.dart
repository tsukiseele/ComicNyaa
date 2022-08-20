import 'dart:async';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:comic_nyaa/library/mio/core/mio_loader.dart';
import 'package:comic_nyaa/utils/http.dart';
import 'package:comic_nyaa/views/detail/comic_detail_view.dart';
import 'package:comic_nyaa/views/detail/image_detail_view.dart';
import 'package:comic_nyaa/views/detail/video_detail_view.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

import 'package:comic_nyaa/library/mio/model/site.dart';
import 'package:comic_nyaa/library/mio/core/mio.dart';
import 'package:comic_nyaa/models/typed_model.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shimmer/shimmer.dart';

import '../../app/global.dart';
import '../../models/typed_model.dart';

class GalleryController {
  String keywords = '';
  void Function(String keywords)? search;
  void Function(double offset, { required Duration duration,   required Curve curve})? animateTo;
}

class GalleryView extends StatefulWidget {
  GalleryView({Key? key, required this.site}) : super(key: key);
  final Site site;
  final GalleryController controller = GalleryController();

  @override
  State<GalleryView> createState() => _GalleryViewState();
}

class _GalleryViewState extends State<GalleryView> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin<GalleryView> {
  final globalKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  final Map<int, double> _heightCache = {};
  List<Site> _sites = [];
  List<TypedModel> _models = [];
  List<TypedModel> _preloadModels = [];
  int _currentSiteId = 920;
  int _page = 1;
  String _keywords = '';
  bool _isLoading = false;

  Future<void> _initialize() async {
    widget.controller.search = (String kwds) {
      _keywords = kwds;
      _refreshController.requestRefresh();
    };

    await _checkUpdate();
    final sites = await RuleLoader.loadFormDirectory(await Config.ruleDir);
    sites.forEachIndexed((i, element) => print('$i: [${element.id}]${element.name}'));
    setState(() {
      _sites = sites;
      _currentSiteId = _currentSiteId < 0 ? _sites[0].id! : _currentSiteId;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshController.requestRefresh();
      widget.controller.animateTo = _scrollController.animateTo;
      _scrollController.addListener(() {
        if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent) {
          if (!_isLoading) {
            _onNext();
          }
        }
        // if (_scrollController.position.pixels < 128) {
        //   _floatingSearchBarController.isHidden ? _floatingSearchBarController.show() : null;
        // } else if (_scrollController.position.pixels > _lastScrollPosition + 64) {
        //   _lastScrollPosition = _scrollController.position.pixels.toInt();
        //   _floatingSearchBarController.isVisible ? _floatingSearchBarController.hide() : null;
        // } else if (_scrollController.position.pixels < _lastScrollPosition - 64) {
        //   _lastScrollPosition = _scrollController.position.pixels.toInt();
        //   _floatingSearchBarController.isHidden ? _floatingSearchBarController.show() : null;
        // }
      });
    });
  }
  /// 加载列表
  Future<List<TypedModel>> _load({bool isNext = false, bool isReset = false}) async {
    print('LIST SIZE: ${_models.length}');
    if (_isLoading) return [];
    try {
      // 重置状态
      if (isReset) {
        _preloadModels = [];
      }
      // 试图获取预加载内容
      if (_preloadModels.isNotEmpty) {
        print('READ PRELOAD ====================== SIZE = ${_preloadModels.length}');
        final models = _preloadModels;
        _page++;
        _preloadModels = [];
        _preload();
        return models;
      }
      // 否则重新加载
      _isLoading = true;
      if (isNext) _page++;
      print('CURRENT PAGE: $_page');
      final images = await _getModels();
      if (images.isEmpty) {
        if (isNext) _page--;
        Fluttertoast.showToast(msg: '已经到底了');
      } else {
        print('SEND PRELOAD =====> PAGE = $_page');
        _preload();
      }
      return images;
    } catch (e) {
      if (isNext) _page--;
      Fluttertoast.showToast(msg: 'ERROR: $e');
    } finally {
      _isLoading = false;
    }
    return [];
  }

  /// 获取数据
  Future<List<TypedModel>> _getModels({Site? site, int? page, String? keywords}) async {
    widget.controller.keywords = _keywords;
    site = site ?? _currentSite;
    page = page ?? _page;
    keywords = keywords ?? _keywords;
    final results = await (Mio(site)
          ..setPage(page)
          ..setKeywords(keywords))
        .parseSite();
    return List.of(results.map((item) => TypedModel.fromJson(item)));
  }

  /// 预加载列表
  Future<void> _preload() async {
    if (_preloadModels.isNotEmpty) return;
    final page = _page + 1;
    try {
      _preloadModels = await _getModels(page: page);
      // 为空则返回
      if (_preloadModels.isEmpty) return;
      // 页码改变则返回
      if (page == _page + 1) {
        // print('CURRENT PAGE: $_page ===> PRELOAD PAGE: $page');
      } else {
        _preloadModels = [];
        return;
      }
      for (var model in _preloadModels) {
        DynamicCacheImageProvider(model.coverUrl ?? '').resolve(const ImageConfiguration());
      }
    } catch (e) {
      print(e);
    }
  }

  Future<List<TypedModel>> _onNext() async {
    if (_isLoading) return [];
    final models = await _load(isNext: true);
    _refreshController.loadComplete();
    setState(() => _models.addAll(models));
    return models;
  }

  Future<List<TypedModel>> _onSearch(String keywords) async {
    setState(() {
      _models = [];
      _heightCache.clear();
    });

    _page = 1;
    _keywords = keywords;
    final models = await _load(isReset: true);
    _refreshController.refreshCompleted();
    setState(() => _models = models);
    return models;
  }

  _onRefresh() async {
    await _onSearch(_keywords);
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
    // return _sites.firstWhereOrNull((site) => site.id == _currentSiteId);
    return widget.site;
  }

  _checkUpdate() async {
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

  Future<ImageInfo> getImageInfo(ImageProvider image) async {
    final c = Completer<ImageInfo>();
    ImageStream imageStream = image.resolve(const ImageConfiguration());
    imageStream.addListener(ImageStreamListener((ImageInfo i, bool _) => c.complete(i)));
    return c.future;
  }

  void cacheHeight(ImageProvider image, int index) async {
    ImageInfo imageInfo = await getImageInfo(image);
    // _heightCache[index] = imageInfo.image.height.toDouble();
    _heightCache[index] = imageInfo.image.width / imageInfo.image.height;

    print('CAHCE HEIGHT: ${_heightCache[index]}');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(children: [
      Flexible(
        child: Scrollbar(
            child: SmartRefresher(
            enablePullDown: true,
            enablePullUp: true,
            header: const WaterDropMaterialHeader(
              distance: 48,
              offset: 96,
            ),
            controller: _refreshController,
            onRefresh: () => _onRefresh(),
            onLoading: () => _onNext(),
            physics: const BouncingScrollPhysics(),
            // onLoading: _onLoading,
            child: MasonryGridView.count(
                padding: const EdgeInsets.fromLTRB(8, kToolbarHeight + 48, 8, 0),
                crossAxisCount: 3,
                mainAxisSpacing: 8.0,
                crossAxisSpacing: 8.0,
                itemCount: _models.length,
                controller: _scrollController,
                // physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final controller = AnimationController(value: 1, duration: const Duration(milliseconds: 500), vsync: this);
                  return Material(
                      clipBehavior: Clip.hardEdge,
                      elevation: 2,
                      borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                      child: InkWell(
                          onTap: () => _jump(_models[index]),
                          child: Column(
                            children: [
                              ExtendedImage.network( _models[index].coverUrl ?? '',
                              headers: _currentSite?.headers,
                              height: _heightCache[index],
                              opacity: controller,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.low,
                              timeRetry: const Duration(milliseconds: 500),
                              timeLimit: const Duration(milliseconds: 5000),
                              loadStateChanged: (state) {
                                switch (state.extendedImageLoadState) {
                                  case LoadState.loading:
                                    controller.reset();
                                    return Shimmer.fromColors(
                                        baseColor: const Color.fromRGBO(240, 240, 240, 1),
                                        highlightColor: Colors.white,
                                        child: AspectRatio(
                                          aspectRatio: 0.66,
                                          child: Container(
                                            decoration: const BoxDecoration(color: Colors.white),
                                          ),
                                        ));
                                  case LoadState.failed:
                                    return const AspectRatio(aspectRatio: 0.66, child: Icon(Icons.image_not_supported, size: 64));
                                  case LoadState.completed:
                                    controller.forward();
                                    return null;
                                }
                              },
                              afterPaintImage: (canvas, rect, image, paint) {
                                  _heightCache[index] = rect.height;
                              }),
                              Container(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  _models[index].title ?? '',
                                  maxLines: 3,
                                ),
                              )
                            ],
                          )));
                }))),
      ),
    ]);
  }

  @override
  bool get wantKeepAlive => true;
}
