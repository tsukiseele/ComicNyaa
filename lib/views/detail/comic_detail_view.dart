import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:comic_nyaa/library/mio/core/mio.dart';
import 'package:comic_nyaa/models/typed_model.dart';
import 'package:comic_nyaa/views/detail/image_detail_view.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
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
  final RefreshController _refreshController = RefreshController();
  final ScrollController _scrollController = ScrollController();
  final List<TypedModel> _children = [];
  final List<String> _tags = [];
  StreamSubscription<List<Map<String, dynamic>>>? _stream;

  void initialized() {
    _scrollController.addListener(() {
      const offset = 32;
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent) {
        print(
            'SCROLL POSITION: ${_scrollController.position.pixels} >= ${_scrollController.position.maxScrollExtent - offset}');
        while (_stream?.isPaused == true) {
          print('STREAM RESUME >>>>>>>>>>>>>>>>>> ');

          _stream?.resume();
        }
      }
    });
    final model = widget.model;
    _tags.addAll(model.tags?.split(' ') ?? []);
    _stream =
        Mio(model.$site).parseChildrenStream(model.toJson(), model.$section!.rules!).listen((List<Map<String, dynamic>> data) {
      _stream?.pause();
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
      rethrow;
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
    Theme.of(context).primaryColor;
    final statusBarHeight = MediaQuery.of(context).viewPadding.top;
    return Scaffold(
      // appBar: AppBar(
      //   title: Text(widget.title),
      // ),
      body: SmartRefresher(
          controller: _refreshController,
          header: SliverToBoxAdapter(
            child: Material(elevation: 4, child: Container(
                color: Theme.of(context).primaryColor.withOpacity(.75),
                padding: EdgeInsets.only(left: 8, top: statusBarHeight + 8, right: 8, bottom: 8),
                child: Column(children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Material(
                      elevation: 8,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: ExtendedImage.network(
                          widget.model.coverUrl ?? '',
                          height: 192,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                          margin: const EdgeInsets.only(left: 8),
                          child: Text(
                            widget.model.title ?? 'Unknown',
                            style: const TextStyle(color: Colors.white, fontSize: 20),
                          )),
                    )
                  ]),
                  Wrap(children: List.generate(_tags.length, (i) => Text(_tags[i]))),
                ]))),
          ),
          child: _children.isNotEmpty
              ? MasonryGridView.count(
                  // controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  crossAxisCount: 3,
                  mainAxisSpacing: 8.0,
                  crossAxisSpacing: 8.0,
                  itemCount: _children.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    return Material(
                      shadowColor: Colors.black45,//Colors.grey[100],
                        elevation: 2,
                        borderRadius: const BorderRadius.all(Radius.circular(2.0)),
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
    );
  }

  @override
  void dispose() {
    super.dispose();
    _stream?.cancel();
  }
}
