import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:comic_nyaa/app/global.dart';
import 'package:comic_nyaa/library/mio/core/mio.dart';
import 'package:comic_nyaa/models/typed_model.dart';
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

class ImageDetailView extends StatefulWidget {
  const ImageDetailView({Key? key, required this.models, this.index = 0}) : super(key: key);
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
  List<TypedModel>? _models;
  List<String> _images = [];
  int currentIndex = 0;
  bool isFailed = false;

  void loadImage() async {
    print('INDEX: ${widget.index}, WIDGET.MODELS: ${widget.models}');
    try {
      final models = widget.models;
      // 只有一条数据，且无图片源，则请求解析
      if (models.length == 1 && getUrl(models.first).isEmpty) {
        var model = models.first;
        print('MODEL.SECTION: ${model.$section}');
        final result = await Mio(model.$site).parseChildrenConcurrency(model.toJson(), model.$section!.rules!);
        model = TypedModel.fromJson(result);
        if (model.children != null) {
          _updateModels(model.children ?? []);
        } else {
          _updateModels([model]);
        }
      } else {
        _updateModels(models);
      }
      setState(() {
        currentIndex = widget.index;
        isFailed = _images.length > currentIndex ? _images[currentIndex].isNotEmpty : true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if(_pageController.hasClients){
          _pageController.jumpToPage(widget.index);
        }
      });
    } catch (e) {
      print('ERROR: ${e.toString()}');
    }
  }

  _updateModels(List<TypedModel> models) {
    _models = models;
    _images = models.map((model) => getUrl(model)).toList();
  }

  String getUrl(TypedModel? item) {
    if (item == null) return '';
    String url = "";
    try {
      final children = item.children != null ? item.children![0] : null;
      if (children != null) {
        url = children.sampleUrl ?? children.largerUrl ?? children.originUrl ?? '';
        return url;
      }
      url = item.sampleUrl ?? item.largerUrl ?? item.originUrl ?? '';
    } catch (e) {
      Fluttertoast.showToast(msg: 'ERROR: $e');
    }
    return Uri.encodeFull(url);
  }

  onDownload(String url) async {
    String savePath = (await Config.downloadDir).join(Uri.parse(url).filename()).path;
    Fluttertoast.showToast(msg: '下载已添加：$savePath');
    await Dio().download(url, savePath);
  }

  @override
  void initState() {
    loadImage();
    super.initState();
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
                backgroundDecoration: const BoxDecoration(color: Colors.black87),
                scrollPhysics: const BouncingScrollPhysics(),
                builder: (BuildContext context, int index) {
                  return PhotoViewGalleryPageOptions(
                      imageProvider: ExtendedImage.network(
                        _images[index],
                        headers: _models?[index].$site?.headers,
                      ).image,
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
                    radius: 56,
                    lineWidth: 12,
                    progressColor: Colors.teal,
                    animation: true,
                    animateFromLastPercent: true,
                    circularStrokeCap: CircularStrokeCap.round,
                    percent: event == null ? 0 : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? -1),
                    center: Text(
                      '${(event == null ? 0 : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? -1) * 100).toInt()}%',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
                    ),
                    footer: Container(
                        margin: const EdgeInsets.only(top: 8),
                        child: const Text(
                          "Loading...",
                          style: TextStyle(fontFamily: '', fontSize: 16.0, color: Colors.white70),
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
                      ))
        );
  }
}
