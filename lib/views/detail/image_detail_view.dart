import 'package:comic_nyaa/app/global.dart';
import 'package:comic_nyaa/library/mio/core/mio.dart';
import 'package:comic_nyaa/models/typed_model.dart';
import 'package:comic_nyaa/utils/uri_extensions.dart';
import 'package:dio/dio.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class ImageDetailView extends StatefulWidget {
  const ImageDetailView({Key? key, required this.model}) : super(key: key);
  final title = '画廊';
  final TypedModel model;

  @override
  State<StatefulWidget> createState() {
    return ImageDetailViewState();
  }
}

class ImageDetailViewState extends State<ImageDetailView> {
  TypedModel? _model;
  List<TypedModel>? _children;
  int currentIndex = 0;
  bool isFailed = false;

  void getChildren() async {
    try {
      final model = widget.model;
      print('model.\$section: ${model.$section}');
      final dynamicResult = await Mio(model.$site).parseChildrenConcurrency(model.toJson(), model.$section!.rules!);
      // print('SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS: ${model.$site?.sections?['search']?.toJson().toString()}');
      _model = TypedModel.fromJson(dynamicResult);
      // print('XXXXXXXXXXXXXXXXXXXXXXXX: $dynamicResult');
      // print('CHILDREN URL: ${getUrl(_model)}');
      final url = getUrl(_model);

      setState(() {
        isFailed = url.isEmpty;
        // print('ISFAILED: ${isFailed}');
        _children = _model?.children; //TypedModel.fromJson(dynamicResult);
      });
    } catch (e) {
      print('ERROR: ${e.toString()}');
    }
    // return data;;
  }

  String getUrl(TypedModel? item) {
    if (item == null) return '';
    String url = "";
    try {
      final children = item.children != null ? item.children![0] : null;
      if (children != null) {
        url = children.sampleUrl ?? children.largerUrl ?? children.originUrl ?? '';
      }
      url = item.sampleUrl ?? item.largerUrl ?? item.originUrl ?? '';
    } catch (e) {
      Fluttertoast.showToast(msg: 'ERROR: $e');
    }
    return Uri.encodeFull(url);
  }

  onDownload(String url) async {
    // String savePath = (await Config.downloadDir).concatPath(getFilename(url)).path;
    String savePath = (await Config.downloadDir).concatPath(Uri.parse(url).filename()).path;
    print('SAVE PATH: $savePath');
    Dio().download(url, savePath);
  }

  @override
  void initState() {
    getChildren();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _children != null
          ? Center(
              child: PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              builder: (BuildContext context, int index) {
                return PhotoViewGalleryPageOptions(
                    imageProvider: ExtendedImage.network(getUrl(_children?[index])).image,
                    initialScale: PhotoViewComputedScale.contained * 1,
                    onTapUp: (context, detail, value) {
                      final url = getUrl(_children?[index]);
                      Fluttertoast.showToast(msg: '下载已添加：${url}');
                      onDownload(url);
                    },
                    onTapDown: (context, detail, value) {}
                    // heroAttributes: PhotoViewHeroAttributes(tag: _children?[index].id),
                    );
              },
              itemCount: _children?.length,
              loadingBuilder: (context, event) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: event == null ? 0 : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? -1),
                    ),
                    Text('${((event?.cumulativeBytesLoaded ?? 0) / (event?.expectedTotalBytes ?? 1) * 100).toInt()}%')
                  ],
                ),
              ),
              // backgroundDecoration: widget.backgroundDecoration,
              // pageController: widget.pageController,
              // onPageChanged: onPageChanged,
            ))
          : isFailed
              ? const Center(child: Text('加载失败'))
              : const Center(child: CircularProgressIndicator()),
    );

    //     return Stack(children: [
    //   _children != null
    //       ? PhotoViewGallery.builder(
    //           scrollPhysics: const BouncingScrollPhysics(),
    //           builder: (BuildContext context, int index) {
    //             return PhotoViewGalleryPageOptions(
    //                 imageProvider: ExtendedImage.network(getUrl(_children?[index])).image,
    //                 initialScale: PhotoViewComputedScale.contained * 0.8,
    //                 onTapUp: (context, detail, value) {
    //                   final url = getUrl(_children?[index]);
    //                   Fluttertoast.showToast(msg: '下载已添加：${url}');
    //                   onDownload(url);
    //                 },
    //                 onTapDown: (context, detail, value) {}
    //                 // heroAttributes: PhotoViewHeroAttributes(tag: _children?[index].id),
    //                 );
    //           },
    //           itemCount: _children?.length,
    //           loadingBuilder: (context, event) => Center(
    //             child: CircularProgressIndicator(
    //               value: event == null ? 0 : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? -1),
    //             ),
    //           ),
    //           // backgroundDecoration: widget.backgroundDecoration,
    //           // pageController: widget.pageController,
    //           // onPageChanged: onPageChanged,
    //         )
    //       : isFailed
    //           ? const Center(child: Text('加载失败'))
    //           : const Center(child: CircularProgressIndicator()),
  }
}
