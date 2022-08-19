import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:comic_nyaa/library/mio/core/mio.dart';
import 'package:comic_nyaa/models/typed_model.dart';
import 'package:comic_nyaa/views/detail/image_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shimmer/shimmer.dart';

class ComicDetailView extends StatefulWidget {
  const ComicDetailView({Key? key, required this.model}) : super(key: key);
  final title = '漫画';
  final TypedModel model;

  @override
  State<StatefulWidget> createState() {
    return ComicDetailViewState();
  }
}

class ComicDetailViewState extends State<ComicDetailView> {
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<List<Map<String, dynamic>>>? stream;
  final List<TypedModel> _children = [];
  int streamIndex = 0;

  void initialized() {
    _scrollController.addListener(() {
      const offset = 32;
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent) {
        print(
            'SCROLL POSITION: ${_scrollController.position.pixels} >= ${_scrollController.position.maxScrollExtent - offset}');
        while (stream?.isPaused == true) {
          print('STREAM RESUME >>>>>>>>>>>>>>>>>> ');

          stream?.resume();
        }
      }
    });
    final model = widget.model;
    stream =
        Mio(model.$site).parseChildrenStream(model.toJson(), model.$section!.rules!).listen((List<Map<String, dynamic>> data) {
      stream?.pause();
      _getNext(data);
    });
  }

  _getNext(List<Map<String, dynamic>> data) async {
    try {
      final models = data.map((item) => TypedModel.fromJson(item)).toList();
      setState(() {
        _children.addAll(models);
      });
    } catch (e) {
      Fluttertoast.showToast(msg: 'ERROR: ${e.toString()}');
      print('ERROR: ${e.toString()}');
    }
    return data;
  }

  String getUrl(TypedModel? item) {
    if (item == null) return '';
    try {
      final children = item.children != null ? item.children![0] : null;
      if (children != null) {
        return children.coverUrl ?? children.sampleUrl ?? children.largerUrl ?? children.originUrl ?? '';
      }
      return item.coverUrl ?? item.sampleUrl ?? item.largerUrl ?? item.originUrl ?? '';
    } catch (e) {
      print('ERROR: $e');
    }
    return '';
  }

  @override
  void initState() {
    initialized();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Container(
            padding: const EdgeInsets.all(8.0),
            child: Column(children: [
              Flexible(
                  child: _children.isNotEmpty
                      ? MasonryGridView.count(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                          crossAxisCount: 3,
                          mainAxisSpacing: 8.0,
                          crossAxisSpacing: 8.0,
                          itemCount: _children.length,
                          itemBuilder: (context, index) {
                            return Material(
                                elevation: 2.0,
                                borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                                child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (ctx) => ImageDetailView(
                                                    models: _children,
                                                    index: index,
                                                  )));
                                    },
                                    child: Column(
                                      children: [
                                        CachedNetworkImage(
                                          imageUrl: getUrl(_children[index]),
                                          httpHeaders: widget.model.$site?.headers,
                                          height: 160,
                                          fit: BoxFit.cover,
                                          placeholder: (ctx, text) => Shimmer.fromColors(
                                              baseColor: const Color.fromRGBO(240, 240, 240, 1),
                                              highlightColor: Colors.white,
                                              child: AspectRatio(
                                                aspectRatio: 0.8,
                                                child: Container(
                                                  decoration: const BoxDecoration(color: Colors.white),
                                                ),
                                              )),
                                          errorWidget: (ctx, url, error) => const AspectRatio(
                                              aspectRatio: 1,
                                              child: Icon(
                                                Icons.image_not_supported,
                                                size: 64,
                                                color: Colors.redAccent,
                                              )),
                                        ),
                                        // ExtendedImage.network(
                                        //   getUrl(_children?[index]),
                                        //   height: _heightCache[index],
                                        //   fit: BoxFit.cover,
                                        //   cache: true,
                                        //   handleLoadingProgress: true,
                                        //   gaplessPlayback: true,
                                        //   timeRetry: const Duration(milliseconds: 1000),
                                        //   // border: Border.all(color: Colors.red, width: 1.0),
                                        //   // shape: boxShape,
                                        //   borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                                        //   //cancelToken: cancellationToken,
                                        //   afterPaintImage: (Canvas canvas, Rect rect, image, Paint paint) {
                                        //     if (_heightCache[index] == null) {
                                        //       _heightCache[index] = rect.height;
                                        //     }
                                        //   },
                                        //   loadStateChanged: (status) {
                                        //     switch (status.extendedImageLoadState) {
                                        //       case LoadState.failed:
                                        //         return Container(
                                        //             decoration: const BoxDecoration(color: Colors.white),
                                        //             height: 96,
                                        //             width: double.infinity,
                                        //             child: const Icon(
                                        //               Icons.close,
                                        //               size: 40,
                                        //               color: Colors.black,
                                        //             ));
                                        //       case LoadState.loading:
                                        //         return Container(
                                        //             decoration: const BoxDecoration(color: Colors.white),
                                        //             height: 192,
                                        //             child: const SpinKitFoldingCube(
                                        //               color: Colors.teal,
                                        //               size: 40.0,
                                        //             ));
                                        //       case LoadState.completed:
                                        //         break;
                                        //     }
                                        //     return null;
                                        //   },
                                        // ),
                                        Container(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(_children[index].title ?? ''),
                                        )
                                      ],
                                    )));
                          })
                      : const Center(
                          child: SpinKitSpinningLines(
                          color: Colors.teal,
                          size: 64,
                        ))),
            ])));
  }

  @override
  void dispose() {
    super.dispose();
    stream?.cancel();
  }
}
