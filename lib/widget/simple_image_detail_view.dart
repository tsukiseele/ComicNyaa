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

import 'package:comic_nyaa/app/app_config.dart';
import 'package:comic_nyaa/library/mio/core/mio.dart';
import 'package:comic_nyaa/library/mio/model/data_origin.dart';
import 'package:comic_nyaa/models/typed_model.dart';
import 'package:comic_nyaa/utils/extensions.dart';
import 'package:comic_nyaa/utils/num_extensions.dart';
import 'package:comic_nyaa/utils/string_extensions.dart';
import 'package:comic_nyaa/utils/uri_extensions.dart';
import 'package:comic_nyaa/views/main_view.dart';
import 'package:comic_nyaa/widget/nyaa_tag_item.dart';
import 'package:comic_nyaa/widget/nyaa_tags.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../app/app_preference.dart';
import '../library/http/http.dart';
import '../utils/flutter_utils.dart';

class SimpleImageDetailView extends StatefulWidget {
  const SimpleImageDetailView({Key? key, required this.models, this.index = 0})
      : assert(models.length > 0),
        super(key: key);
  final title = '画廊';
  final List<TypedModel> models;
  final int index;

  @override
  State<StatefulWidget> createState() {
    return _SimpleImageDetailViewState();
  }
}

class _SimpleImageDetailViewState extends State<SimpleImageDetailView>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  final _panelController = PanelController();
  final Set<int> _cache = {};
  late List<TypedModel> _models;
  late DataOrigin _origin;
  List<String> _images = [];
  int _currentIndex = 0;
  AnimationController? _animationController;
  Animation<double>? _animation;

  void _initialized() async {
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    try {
      _currentIndex = widget.index;
      _models = List.of(widget.models);
      _images = List.filled(_models.length, '');
      _origin = _models[0].getOrigin();

      _loadImage(_currentIndex);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients &&
            _images.isNotEmpty &&
            widget.index < _images.length) {
          _pageController.jumpToPage(widget.index);
        }
      });
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
      rethrow;
    }
  }

  void _loadImage(int index) async {
    _cache.add(index);
    if (_images[index].isNotEmpty) {
      return;
    }
    TypedModel model = _models[index];
    String image = model.availablePreviewUrl;
    if (image.isEmpty) {
      final results = await Mio(_origin.site).parseAllChildren(model.toJson());
      final m = TypedModel.fromJson(results);
      if (m.children?.isNotEmpty == true) {
        final models = m.children;
        if (models == null) {
          Fluttertoast.showToast(msg: '解析异常：没有可用数据');
          return;
        }
        if (models.length == 1) {
          model = models[0];
          image = models[0].availablePreviewUrl;
        } else {
          Fluttertoast.showToast(msg: '解析异常：预料之外的子数据集');
          return;
        }
      } else {
        model = m;
        image = m.availablePreviewUrl;
      }
    }
    setState(() {
      _images[index] = image;
      _models[index] = model;
    });
  }

  /// 预加载，默认预加载前后2页
  void _preload(int index, {int range = 2}) {
    int start = index - range > 0 ? index - range : 0;
    int end =
        index + range < _images.length ? index + range : _images.length - 1;
    if (start < end) {
      for (int i = start; i <= end; i++) {
        if (!_cache.contains(i)) _loadImage(i);
      }
    } else {
      _loadImage(index);
    }
  }

  void _onDownload(TypedModel model) async {
    try {
      final downloadLevel =
          (await AppPreferences.instance).downloadResourceLevel;
      String? url;
      switch (downloadLevel) {
        case DownloadResourceLevel.low:
          url = model.sampleUrl ?? model.largerUrl ?? model.originUrl;
          break;
        case DownloadResourceLevel.medium:
          url = model.largerUrl ?? model.originUrl ?? model.sampleUrl;
          break;
        case DownloadResourceLevel.high:
          url = model.originUrl ?? model.largerUrl ?? model.sampleUrl;
          break;
      }
      if (url == null || url.trim().isEmpty) {
        Fluttertoast.showToast(msg: '下载失败，无有效下载源');
        return;
      }
      String savePath =
          (await AppConfig.downloadDir).join(Uri.parse(url).filename);
      Fluttertoast.showToast(msg: '下载已添加：$savePath');
      await Http.downloadFile(url, savePath, headers: _origin.site.headers);

      print('Download =====> $savePath');
    } catch (e) {
      print('DOWNLOAD ERROR: $e');
    }
  }

  @override
  void initState() {
    _initialized();
    super.initState();
  }

  Widget _buildLoading() {
    return const Center(
        child: SpinKitSpinningLines(
      color: Colors.teal,
      size: 64,
    ));
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    final padding = MediaQuery.of(context).padding;
    double viewportHeight = screenHeight - padding.top - padding.bottom;
    return Scaffold(
        body: SlidingUpPanel(
            controller: _panelController,
            body: Material(
                color: Colors.black,
                child: ExtendedImageGesturePageView.builder(
                  itemCount: _images.length,
                  scrollDirection: Axis.horizontal,
                  controller: ExtendedPageController(
                    initialPage: _currentIndex,
                  ),
                  onPageChanged: (int index) {
                    _currentIndex = index;
                    // 预加载
                    _preload(index);
                    setState(() {});
                  },
                  itemBuilder: (BuildContext context, int index) {
                    var item = _images[index];
                    if (item.isEmpty) {
                      return _buildLoading();
                    }
                    void Function() animationListener = () {};
                    Widget image = ExtendedImage.network(
                      height: viewportHeight,
                      item,
                      fit: BoxFit.contain,
                      mode: ExtendedImageMode.gesture,
                      handleLoadingProgress: true,
                      headers: _origin.site.headers,
                      onDoubleTap: (state) {
                        // reset animation
                        _animation?.removeListener(animationListener);
                        _animationController?.stop();
                        _animationController?.reset();
                        // animation start
                        final image = state
                            .widget.extendedImageState.extendedImageInfo?.image;
                        final layout = state.gestureDetails?.layoutRect;
                        // final screen = MediaQuery.of(context).size;
                        final doubleTapScales = <double>[1.0];
                        // 计算全屏缩放比例
                        if (image != null && layout != null) {
                          // print('IMAGE_W: ${image.width}, IMAGE_H: ${image.height}');
                          // print('CONTAINER_SIZE: ${layout.width} x ${layout.height}');
                          // print('SCREEN_SIZE: ${screen.width} x ${screen.height}');
                          final widthScale = image.width / layout.width;
                          final heightScale = image.height / layout.height;
                          if (widthScale > heightScale) {
                            doubleTapScales.add(widthScale / heightScale);
                            doubleTapScales.add(widthScale);
                          } else {
                            doubleTapScales.add(heightScale / widthScale);
                            doubleTapScales.add(heightScale);
                          }
                        } else {
                          doubleTapScales.add(2.0);
                        }
                        // 默认尺寸
                        Offset? pointerDownPosition = state.pointerDownPosition;
                        double begin = state.gestureDetails?.totalScale ?? 1.0;
                        double end;

                        int currentScaleIndex = doubleTapScales
                            .indexWhere((item) => (begin - item).abs() < 0.01);
                        end = doubleTapScales[
                            currentScaleIndex + 1 < doubleTapScales.length
                                ? currentScaleIndex + 1
                                : 0];
                        // print('SCALES::: $doubleTapScales');
                        // print('begin: $begin, end: $end;');
                        animationListener = () {
                          state.handleDoubleTap(
                              scale: _animation?.value,
                              doubleTapPosition: pointerDownPosition);
                        };
                        _animation = Tween<double>(begin: begin, end: end)
                            .animate(CurvedAnimation(
                                parent: _animationController!,
                                curve: Curves.ease));
                        _animation?.addListener(animationListener);
                        _animationController?.forward();
                      },
                      loadStateChanged: (state) {
                        switch (state.extendedImageLoadState) {
                          case LoadState.loading:
                            final event = state.loadingProgress;
                            double? progress;
                            if (event == null) {
                              progress = 0;
                            } else {
                              if (event.expectedTotalBytes != null &&
                                  event.expectedTotalBytes! > 0) {
                                progress = event.cumulativeBytesLoaded /
                                    (event.expectedTotalBytes!);
                              }
                            }
                            return CircularPercentIndicator(
                                radius: 48,
                                lineWidth: 8,
                                progressColor: Colors.teal,
                                animation: true,
                                animateFromLastPercent: true,
                                circularStrokeCap: CircularStrokeCap.round,
                                percent: progress ?? 0,
                                center: Text(
                                  event != null
                                      ? getProgressText(
                                          event.cumulativeBytesLoaded,
                                          event.expectedTotalBytes ?? 0)
                                      : 'Loading',
                                  style: const TextStyle(
                                      fontSize: 18, color: Colors.white70),
                                ));
                          case LoadState.failed:
                            return const Center(
                                child:
                                    Icon(Icons.image_not_supported, size: 64));
                          case LoadState.completed:
                            return null;
                        }
                      },
                      initGestureConfigHandler: (ExtendedImageState state) =>
                          GestureConfig(
                        minScale: 0.1,
                        maxScale: double.infinity,
                        inPageView: true,
                        initialScale: 1.0,
                        cacheGesture: false,
                      ),
                    );
                    image = InkWell(
                      onLongPress: () => _onDownload(_models[_currentIndex]),
                      child: image,
                    );
                    if (index == _currentIndex) {
                      return Hero(
                        tag: item + index.toString(),
                        child: image,
                      );
                    } else {
                      return image;
                    }
                  },
                )),
            minHeight: 64,
            maxHeight: screenHeight * 0.667,
            isDraggable: true,
            backdropEnabled: true,
            backdropOpacity: .3,
            parallaxEnabled: true,
            parallaxOffset: .1,
            color: Colors.transparent,
            boxShadow: const [],
            collapsed: Container(
                color: Colors.black12,
                height: double.maxFinite,
                child: InkWell(
                    onTap: () => _panelController.open(),
                    child: const Icon(
                      Icons.keyboard_arrow_up,
                      color: Colors.white,
                      size: 32,
                    ))),
          panelBuilder: (scrollController) => _buildScrollPanel(scrollController),
        ));
  }

  Widget _buildScrollPanel(ScrollController scrollController) {
    final tags = StringUtil.value(_models[_currentIndex].tags?.trim(),
            widget.models[_currentIndex].tags)
        .split(' ').where((tag) => tag.trim().isNotEmpty).toList();
    final title =
        _models[_currentIndex].title ?? widget.models[_currentIndex].title;
    return Container(
        margin: const EdgeInsets.only(top: 64),
        child: Material(
            borderRadius: BorderRadius.circular(16),
            child: ListView(
              controller: scrollController,
                padding: const EdgeInsets.only(
                    top: 8, left: 16, bottom: 24, right: 16),
                children: [
                  _buildTitleView('标题'),
                  Text(title ?? ''),
                  _buildTitleView('标签'),
                  NyaaTags(
                      itemCount: tags.length,
                      builder: (ctx, index) =>
                          NyaaTagItem(text: tags[index], color: Colors.teal, onTap: () {
                            RouteUtil.push(
                                context,
                                MainView(site: widget.models[0].getOrigin().site, keywords: tags[index]));
                          },)),
                  _buildTitleView('预览源'),
                  _buildLink(_models[_currentIndex].sampleUrl ?? '无'),
                  _buildTitleView('压缩源'),
                  _buildLink(_models[_currentIndex].largerUrl ?? '无'),
                  _buildTitleView('原始源'),
                  _buildLink(_models[_currentIndex].originUrl ?? '无'),
                ])));
  }

  Widget _buildTitleView(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18),
      ),
    );
  }

  Widget _buildLink(String url) {
    return InkWell(
            onTap: () async {
              if (await canLaunchUrlString(url)) {
                await launchUrlString(url);
              } else {
                throw "Could not launch $url";
              }
            },
            child: Text(
              url,
              style: const TextStyle(
                  color: Colors.teal, decoration: TextDecoration.underline),
            ));
  }
}
