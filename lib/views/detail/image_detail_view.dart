import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
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
import 'package:material_floating_search_bar/material_floating_search_bar.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../library/mio/model/site.dart';

class ImageDetailView extends StatefulWidget {
  const ImageDetailView({Key? key, required this.models, this.index = 0})
      : super(key: key);
  final title = '画廊';
  final List<TypedModel> models;
  final int index;

  @override
  State<StatefulWidget> createState() {
    return ImageDetailViewState();
  }
}

class ImageDetailViewState extends State<ImageDetailView> {
  final PageController _pageController = PageController();
  late List<TypedModel> _models;
  List<String> _images = [];
  Site? _site;
  int currentIndex = 0;
  bool isFailed = false;

  void loadSingle(int index) async {
    if (_images[index].isNotEmpty) {
      return;
    }
    TypedModel model = _models[index];
    String image = getUrl(model);
    if (image.isEmpty) {
      print('LOAD SINGLE:::: $model');
      print(
          'LOAD SINGLE:::: ${model.$section?.rules?[r'$children']?.selector}');
      // return;
      final results = await Mio(model.$site)
          .parseChildrenDeep(model.toJson(), model.$section!.rules!);
      final tm = TypedModel.fromJson(results);
      if (tm.children?.isNotEmpty == true) {
        final models = tm.children;
        if (models == null) {
          Fluttertoast.showToast(msg: '解析异常：没有可用数据');
          return;
        }
        if (models.length == 1) {
          model = models[0];
          image = getUrl(models[0]);
          print('MMMMMMMMMMMMMMMMMMMMMMMMMMM === $model');

          print('UUUUUUUUUUUUUUUUUUUUUUUUUUU === $image');
        } else {
          Fluttertoast.showToast(msg: '解析异常：预料之外的子数据集');
          return;
        }
      } else {
        model = tm;
        image = getUrl(tm);
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
    // print('INDEX: ${widget.index}, WIDGET.MODELS: ${widget.models}');
    try {
      currentIndex = widget.index;
      _models = widget.models;
      _images = List.filled(_models.length, '');
      _site = _models.isNotEmpty ? _models[0].$site : null;
      // // 只有一条数据，且无图片源，则请求解析

      loadSingle(currentIndex);
      // if (models.length == 1 && getUrl(models.first).isEmpty) {
      //   var model = models.first;
      //   // print('MODEL.SECTION: ${model.$section}');
      //   final result = await Mio(model.$site).parseChildrenDeep(model.toJson(), model.$section.rules!);
      //   model = TypedModel.fromJson(result);
      //   if (model.children != null) {
      //     _updateModels(model.children ?? []);
      //   } else {
      //     _updateModels([model]);
      //   }
      // } else {
      //   _updateModels(models);
      // }
      setState(() {
        currentIndex = widget.index;
        isFailed = _images.length > currentIndex
            ? _images[currentIndex].isNotEmpty
            : true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients &&
            _images.isNotEmpty &&
            widget.index < _images.length) {
          _pageController.jumpToPage(widget.index);
        }
      });
    } catch (e) {
      rethrow;
      // print('ERROR: ${e.toString()}');
    }
  }

  _updateModels(List<TypedModel> models) {
    _models = models;
    _images = models.map((model) => getUrl(model)).toList();
    print('HEADERS ================== ${_models[0].$site?.headers}');
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
        body: _images.isNotEmpty
            ? PhotoViewGallery.builder(
                pageController: _pageController,
                backgroundDecoration:
                    const BoxDecoration(color: Colors.black87),
                scrollPhysics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  loadSingle(index);
                },
                builder: (BuildContext context, int index) {
                  return PhotoViewGalleryPageOptions(
                      // imageProvider: ExtendedImage.network(
                      //   _images[index],
                      //   headers: _models?[index].$site?.headers,
                      // ).image,
                      imageProvider: CachedNetworkImageProvider(_images[index],
                          headers: _site?.headers),
                      initialScale: PhotoViewComputedScale.contained * 1,
                      onTapUp: (context, detail, value) {
                        final url = _images[index];
                        onDownload(url);
                      },
                      onTapDown: (context, detail, value) {}
                      // heroAttributes: PhotoViewHeroAttributes(tag: _children?[index].id),
                      );
                },
                itemCount: _images.length,
                loadingBuilder: (context, event) => Container(
                  alignment: Alignment.center,
                  child: CircularPercentIndicator(
                    radius: 48,
                    lineWidth: 8,
                    progressColor: Colors.teal,
                    animation: true,
                    animateFromLastPercent: true,
                    circularStrokeCap: CircularStrokeCap.round,
                    percent: event == null || event.expectedTotalBytes == null
                        ? 0
                        : event.cumulativeBytesLoaded /
                            event.expectedTotalBytes!,
                    center: Text(
                      event == null
                          ? 'Loading...'
                          : _getProgressText(event.cumulativeBytesLoaded,
                              event.expectedTotalBytes ?? 0),
                      style: TextStyle(fontSize: event == null ? 16 : 18),
                    ),
                    footer: Container(
                        margin: const EdgeInsets.only(top: 8),
                        child: const Text(
                          "Loading...",
                          style: TextStyle(
                              fontFamily: '',
                              fontSize: 16.0,
                              color: Colors.white70),
                        )),
                  ),
                ),
                // backgroundDecoration: widget.backgroundDecoration,
                // pageController: widget.pageController,
                // onPageChanged: onPageChanged,
              )
            : Container(
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
                      )));
  }
}
