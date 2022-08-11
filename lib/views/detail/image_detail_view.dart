import 'package:comic_nyaa/library/mio/core/mio.dart';
import 'package:comic_nyaa/models/typed_model.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
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

  void getChildren() async {
    try {
      final model = widget.model;
      print('model.\$section: ${model.$section}');
      final dynamicResult = await Mio(model.$site).parseChildrenConcurrency(model.toJson(), model.$section!.rules!);
      _model = TypedModel.fromJson(dynamicResult);

      setState(() {
        _children = _model?.children; //TypedModel.fromJson(dynamicResult);
      });
    } catch (e) {
      print('ERROR: ${e.toString()}');
    }
    // return data;;
  }

  String getUrl(TypedModel? item) {
    if (item == null) return '';
    try {
      final children = item.children != null ? item.children![0] : null;
      if (children != null) {
        return children.sampleUrl ?? children.largerUrl ?? children.originUrl ?? '';
      }
      return item.sampleUrl ?? item.largerUrl ?? item.originUrl ?? '';
    } catch (e) {
      print('ERROR: $e');
    }
    return '';
  }

  @override
  void initState() {
    getChildren();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // return Scaffold(
    //     appBar: AppBar(
    //       title: Text(widget.title),
    //     ),
    //     body:
    return Stack(children: [
      _children != null
          ? PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              builder: (BuildContext context, int index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider:
                      ExtendedImage.network(getUrl(_children?[index]), handleLoadingProgress: true, loadStateChanged: (status) {
                    // status.loadingProgress.cumulativeBytesLoaded
                    print('PROGRESS: ${status.loadingProgress}');
                    return null;
                  }).image,
                  initialScale: PhotoViewComputedScale.contained * 0.8,
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
          : const Center(child: CircularProgressIndicator()),
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
