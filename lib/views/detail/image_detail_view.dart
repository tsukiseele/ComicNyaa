import 'package:cached_network_image/cached_network_image.dart';
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
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

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

class ImageDetailViewState extends State<ImageDetailView> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late List<TypedModel> _models;
  List<String> _images = [];
  Site? _site;
  int _currentIndex = 0;
  bool isFailed = false;

  void loadSingle(int index) async {
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

    print('D_IMAGE::: $image');
    print('D_MODEL::: $model');
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

  void loadImage() async {
    try {
      _currentIndex = widget.index;
      _models = widget.models;
      _images = List.filled(_models.length, '');
      _site = _models[0].$site;

      loadSingle(_currentIndex);

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

  onDownload(String url) async {
    String savePath =
        (await Config.downloadDir).join(Uri.parse(url).filename).path;
    Fluttertoast.showToast(msg: '下载已添加：$savePath');
    await Dio().download(url, savePath);
  }

  @override
  void initState() {
    loadImage();
    super.initState();
  }

  String _getProgressText(int current, int total) {
    if (total > 0) {
      return '${(current / total * 100).toInt()}%';
    } else {
      return current.readableFileSize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: ExtendedImageGesturePageView.builder(
          itemCount: _images.length,
          scrollDirection: Axis.horizontal,
          controller: ExtendedPageController(
            initialPage: _currentIndex,
          ),
          onPageChanged: (int index) {
            _currentIndex = index;
            loadSingle(index);
          },
          itemBuilder: (BuildContext context, int index) {
            var item = _images[index];
            if (item.isEmpty) {
              return Container(
                  alignment: Alignment.center,
                  child: isFailed
                      ? const Icon(
                          Icons.image_not_supported,
                          size: 64,
                          color: Colors.redAccent,
                        )
                      : const SpinKitSpinningLines(
                          color: Colors.teal,
                          size: 96,
                        ));
            }
            double scale = 1.0;
            final controller = AnimationController(
                value: 1,
                duration: const Duration(milliseconds: 500),
                vsync: this);
            Widget image = ExtendedImage.network(
              item,
              fit: BoxFit.contain,
              mode: ExtendedImageMode.gesture,
              handleLoadingProgress: true,
              opacity: controller,
              loadStateChanged: (state) {
                switch (state.extendedImageLoadState) {
                  case LoadState.loading:
                    controller.reset();
                    final event = state.loadingProgress;
                    if (event == null) {
                      return const Center(child: Text('Loading...'));
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
                    return const Center(child: Icon(Icons.image_not_supported, size: 64));
                  case LoadState.completed:
                    controller.forward();
                    return null;
                }
              },
              initGestureConfigHandler: (ExtendedImageState state) =>
                  GestureConfig(
                      inPageView: true,
                      initialScale: scale,
                      cacheGesture: false),
            );
            image = InkWell(
              onLongPress: () {
                final url = _images[_currentIndex];
                onDownload(url);
              },
              child: Container(
                padding: const EdgeInsets.all(0),
                child: image,
              ),
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
        )

        // InkWell(
        //   onLongPress: () {
        //     Fluttertoast.showToast(msg: 'DOWNLOAD: ${_images[_currentIndex]}');
        //   },
        //     child: PhotoViewGallery.builder(
        //         pageController: _pageController,
        //         backgroundDecoration:
        //             const BoxDecoration(color: Colors.black87),
        //         scrollPhysics: const BouncingScrollPhysics(),
        //         onPageChanged: (index) {
        //           loadSingle(index);
        //         },
        //         builder: (BuildContext context, int index) {
        //           // if (_images[index].isEmpty) {
        //           //   return PhotoViewGalleryPageOptions(imageProvider: Ink.image(image: image))
        //           // }
        //           return PhotoViewGalleryPageOptions(
        //               imageProvider: ExtendedImage.network(
        //                 _images[index],
        //                 headers: _site?.headers,
        //               ).image,
        //               // imageProvider: CachedNetworkImageProvider(_images[index],
        //               //     headers: _site?.headers),
        //               initialScale: PhotoViewComputedScale.contained * 1,
        //               onTapUp: (context, detail, value) {
        //                 final url = _images[index];
        //                 onDownload(url);
        //               },
        //               onTapDown: (context, detail, value) {}
        //               // heroAttributes: PhotoViewHeroAttributes(tag: _children?[index].id),
        //               );
        //         },
        //         itemCount: _images.length,
        //         loadingBuilder: (context, event) => Container(
        //           alignment: Alignment.center,
        //           child: CircularPercentIndicator(
        //             radius: 48,
        //             lineWidth: 8,
        //             progressColor: Colors.teal,
        //             animation: true,
        //             animateFromLastPercent: true,
        //             circularStrokeCap: CircularStrokeCap.round,
        //             percent: event == null || event.expectedTotalBytes == null
        //                 ? 0
        //                 : event.cumulativeBytesLoaded /
        //                     event.expectedTotalBytes!,
        //             center: Text(
        //               event == null
        //                   ? 'Loading...'
        //                   : _getProgressText(event.cumulativeBytesLoaded,
        //                       event.expectedTotalBytes ?? 0),
        //               style: TextStyle(fontSize: event == null ? 16 : 18),
        //             ),
        //             footer: Container(
        //                 margin: const EdgeInsets.only(top: 8),
        //                 child: const Text(
        //                   "Loading...",
        //                   style: TextStyle(
        //                       fontFamily: '',
        //                       fontSize: 16.0,
        //                       color: Colors.white70),
        //                 )),
        //           ),
        //         ),
        //         // backgroundDecoration: widget.backgroundDecoration,
        //         // pageController: widget.pageController,
        //         // onPageChanged: onPageChanged,
        // ))
        );
  }
}
