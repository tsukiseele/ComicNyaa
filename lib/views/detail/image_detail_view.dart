import 'package:comic_nyaa/app/global.dart';
import 'package:comic_nyaa/library/mio/core/mio.dart';
import 'package:comic_nyaa/models/typed_model.dart';
import 'package:comic_nyaa/utils/num_extensions.dart';
import 'package:comic_nyaa/utils/uri_extensions.dart';
import 'package:dio/dio.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../app/preference.dart';
import '../../library/mio/model/site.dart';

class ImageDetailView extends StatefulWidget {
  const ImageDetailView({Key? key, required this.models, this.index = 0})
      : assert(models.length > 0),
        super(key: key);
  final title = '画廊';
  final List<TypedModel> models;
  final int index;

  @override
  State<StatefulWidget> createState() {
    return ImageDetailViewState();
  }
}

class ImageDetailViewState extends State<ImageDetailView>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late List<TypedModel> _models;
  final Set<int> _cache = {};
  List<String> _images = [];
  Site? _site;
  int _currentIndex = 0;
  bool isFailed = false;

  void initialized() async {
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    try {
      _currentIndex = widget.index;
      _models = widget.models;
      _images = List.filled(_models.length, '');
      _site = _models[0].$site;

      loadImage(_currentIndex);

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

  void loadImage(int index) async {
    _cache.add(index);
    if (_images[index].isNotEmpty) {
      return;
    }
    TypedModel model = _models[index];
    String image = getUrl(model);
    if (image.isEmpty) {
      final results = await Mio(model.$site)
          .parseAllChildren(model.toJson(), model.$section!.rules!);
      final m = TypedModel.fromJson(results);
      if (m.children?.isNotEmpty == true) {
        final models = m.children;
        if (models == null) {
          Fluttertoast.showToast(msg: '解析异常：没有可用数据');
          return;
        }
        if (models.length == 1) {
          model = models[0];
          image = getUrl(models[0]);
        } else {
          Fluttertoast.showToast(msg: '解析异常：预料之外的子数据集');
          return;
        }
      } else {
        model = m;
        image = getUrl(m);
      }
    }

    // print('D_IMAGE::: $image');
    // print('D_MODEL::: $model');
    setState(() {
      _images[index] = image;
      _models[index] = model;
    });
    // if (model.children != null) {
    //   _updateModels(model.children ?? []);
    // } else {
    //   _updateModels([model]);
    // }
  }

  /// 预加载，默认预加载前后2页
  void preload(int index, {int range = 2}) {
    int start = index - range > 0 ? index - range : 0;
    int end =
        index + range < _images.length ? index + range : _images.length - 1;
    if (start < end) {
      for (int i = start; i <= end; i++) {
        if (!_cache.contains(i)) loadImage(i);
      }
    } else {
      loadImage(index);
    }
  }

  String getUrl(TypedModel? item) {
    if (item == null) return '';
    String url = "";
    try {
      final children = item.children != null ? item.children![0] : null;
      if (children != null) {
        url = children.sampleUrl ??
            children.largerUrl ??
            children.originUrl ??
            '';
        return url;
      }
      url = item.sampleUrl ?? item.largerUrl ?? item.originUrl ?? '';
    } catch (e) {
      Fluttertoast.showToast(msg: 'ERROR: $e');
    }
    return Uri.encodeFull(url);
  }

  void onDownload(TypedModel model) async {
    try {
      final downloadLevel =
          (await NyaaPreferences.instance).downloadResourceLevel;
      String? url;
      switch (downloadLevel) {
        case DownloadResourceLevel.low:
          url = model.sampleUrl ?? model.largerUrl ?? model.originUrl;
          break;
        case DownloadResourceLevel.middle:
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
          (await Config.downloadDir).join(Uri.parse(url).filename).path;
      Fluttertoast.showToast(msg: '下载已添加：$savePath');
      await Dio().download(url, savePath);

      print('Download =====> $savePath');
    } catch (e) {
      print('DOWNLOAD ERROR: $e');
    }
  }

  @override
  void initState() {
    initialized();
    super.initState();
  }

  String _getProgressText(int current, int total) {
    if (total > 0) {
      return '${(current / total * 100).toInt()}%';
    } else {
      return current.readableFileSize();
    }
  }

  AnimationController? _animationController;
  Animation<double>? _animation;

  Widget buildLoading() {
    return const Center(
        child: SpinKitSpinningLines(
      color: Colors.teal,
      size: 96,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // appBar: AppBar(
        //   title: Text(widget.title),
        // ),
        body: Material(
            color: Colors.black87,
            child: ExtendedImageGesturePageView.builder(
              itemCount: _images.length,
              scrollDirection: Axis.horizontal,
              controller: ExtendedPageController(
                initialPage: _currentIndex,
              ),
              onPageChanged: (int index) {
                _currentIndex = index;
                // 预加载
                preload(index);
              },
              itemBuilder: (BuildContext context, int index) {
                var item = _images[index];
                if (item.isEmpty) {
                  return buildLoading();
                }
                void Function() animationListener = () {};
                Widget image = ExtendedImage.network(
                  item,
                  fit: BoxFit.contain,
                  mode: ExtendedImageMode.gesture,
                  handleLoadingProgress: true,
                  headers: _site?.headers,
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
                        .indexWhere((item) => begin - item < 0.01);
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
                    _animation = Tween<double>(begin: begin, end: end).animate(
                        CurvedAnimation(
                            parent: _animationController!, curve: Curves.ease));
                    _animation?.addListener(animationListener);
                    _animationController?.forward();
                  },
                  loadStateChanged: (state) {
                    switch (state.extendedImageLoadState) {
                      case LoadState.loading:
                        final event = state.loadingProgress;
                        if (event == null) {
                          return buildLoading();
                        }
                        double? progress;
                        if (event.expectedTotalBytes != null &&
                            event.expectedTotalBytes! > 0) {
                          progress = event.cumulativeBytesLoaded /
                              (event.expectedTotalBytes!);
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
                              _getProgressText(event.cumulativeBytesLoaded,
                                  event.expectedTotalBytes ?? 0),
                              style: const TextStyle(fontSize: 18),
                            ));
                      case LoadState.failed:
                        return const Center(
                            child: Icon(Icons.image_not_supported, size: 64));
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
                  onLongPress: () => onDownload(_models[_currentIndex]),
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
            )));
  }
}
