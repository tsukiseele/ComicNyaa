import 'package:comic_nyaa/app/global.dart';
import 'package:comic_nyaa/library/mio/core/mio.dart';
import 'package:comic_nyaa/models/typed_model.dart';
import 'package:dio/dio.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
      print('SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS: ${model.$site?.sections?['search']?.toJson().toString()}');
      _model = TypedModel.fromJson(dynamicResult);
      print('XXXXXXXXXXXXXXXXXXXXXXXX: $dynamicResult');
      print('CHILDREN URL: ${getUrl(_model)}');
      final url = getUrl(_model);

      setState(() {     if (url.isEmpty) {
        isFailed = true;
        print('ISFAILED: ${isFailed}');
      }
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
        url=  children.sampleUrl ?? children.largerUrl ?? children.originUrl ?? '';
      }
      url= item.sampleUrl ?? item.largerUrl ?? item.originUrl ?? '';
    } catch (e) {
      print('ERROR: $e');
    }
    return Uri.encodeFull(url);
  }

  getFilename(String url) {
    // final i = url.lastIndexOf('/')
    // final end = url.substring(start)
    final match = RegExp(r'[\s\S^\/]*\/([\s\S^\/].*?\.\w+)(\?[\s\S^\/]*)?$').allMatches(url);
    if (match.isNotEmpty && match.first.groupCount > 0) {
      final filename = match.first.group(1);
      print('MATCH: $filename');
      return filename!;
    }
    throw Exception('无法从URL中解析文件名：$url');
  }
  onDownload(String url) async {
    final savePath = (await Config.downloadDir).concatPath(getFilename(url));
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
    return Stack(children: [
      _children != null
          ? PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              builder: (BuildContext context, int index) {
                return PhotoViewGalleryPageOptions(
                    imageProvider: ExtendedImage.network(getUrl(_children?[index])).image,
                    initialScale: PhotoViewComputedScale.contained * 0.8,
                    onTapUp: (context, detail, value) {
                      final url =getUrl(_children?[index]);
                      Fluttertoast.showToast(msg: '下载已添加：${url}');
                      onDownload(url);
                    },
                    onTapDown: (context, detail, value) {}
                    // heroAttributes: PhotoViewHeroAttributes(tag: _children?[index].id),
                    );
              },
              itemCount: _children?.length,
              loadingBuilder: (context, event) => Center(
                child: CircularProgressIndicator(
                  value: event == null ? 0 : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? -1),
                ),
              ),
              // backgroundDecoration: widget.backgroundDecoration,
              // pageController: widget.pageController,
              // onPageChanged: onPageChanged,
            )
          : isFailed ? const Center(child: Text('加载失败') ): const Center(child: CircularProgressIndicator()),
      Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: kToolbarHeight + 48,
          child: AppBar(
            // backgroundColor: const Color.fromRGBO(255, 255, 255, .6),
            // foregroundColor: Colors.teal,
            // toolbarHeight: 48,
            title: Text(widget.title),
          ))
    ]);
  }
}
