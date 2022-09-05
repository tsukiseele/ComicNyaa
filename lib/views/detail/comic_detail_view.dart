import 'dart:async';

import 'package:comic_nyaa/library/mio/core/mio.dart';
import 'package:comic_nyaa/library/mio/core/mio_loader.dart';
import 'package:comic_nyaa/library/mio/model/data_origin.dart';
import 'package:comic_nyaa/models/typed_model.dart';
import 'package:comic_nyaa/views/detail/image_detail_view.dart';
import 'package:comic_nyaa/widget/nyaa_tag_item.dart';
import 'package:comic_nyaa/widget/nyaa_tags.dart';
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

class ComicDetailViewState extends State<ComicDetailView>
    with TickerProviderStateMixin {
  final RefreshController _refreshController = RefreshController();
  final ScrollController _scrollController = ScrollController();
  final List<TypedModel> _children = [];
  Set<String> _tags = {};
  late DataOrigin _origin;
  StreamSubscription<List<Map<String, dynamic>>>? _stream;

  void initialized() {
    _scrollController.addListener(() {
      const offset = 32;
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent) {
        print(
            'SCROLL POSITION: ${_scrollController.position.pixels} >= ${_scrollController.position.maxScrollExtent - offset}');
        while (_stream?.isPaused == true) {
          print('STREAM RESUME >>>>>>>>>>>>>>>>>> ');
          _stream?.resume();
        }
      }
    });
    final model = widget.model;
    _origin = model.getOrigin();
    _tags.addAll(model.tags?.split(' ').toSet() ?? {});
    _stream = Mio(_origin.site)
        .parseChildren(model.toJson(), _origin.section.rules!)
        .listen((List<Map<String, dynamic>> data) {
      _stream?.pause();
      _getNext(data);
    });
  }

  _getNext(List<Map<String, dynamic>> data) async {
    try {
      final models = data.map((item) => TypedModel.fromJson(item)).toList();
      if (models.isNotEmpty) {
        for (var item in models) {
          item.tags?.split(RegExp(r'[\s,]+')).forEach((tag) {
            if (tag.trim().isNotEmpty) _tags.add(tag);
          });
        }
        // _tags = models[0].tags!.split(RegExp(r'[\s,]+'));
      }
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
        return children.coverUrl ??
            children.sampleUrl ??
            children.largerUrl ??
            children.originUrl ??
            '';
      }
      return item.coverUrl ??
          item.sampleUrl ??
          item.largerUrl ??
          item.originUrl ??
          '';
    } catch (e) {
      rethrow;
    }
  }

  @override
  void initState() {
    initialized();

    super.initState();
  }

  Widget buildHeader(double statusBarHeight, List<String> tags) {
    return Container(
        color: Theme.of(context).primaryColor.withOpacity(.75),
        padding: EdgeInsets.only(
            top: statusBarHeight + 8, bottom: 8, left: 8, right: 8),
        child: Column(children: [
          SizedBox(
              height: 192,
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      elevation: 8,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: ExtendedImage.network(
                          widget.model.coverUrl ?? '',
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                          margin: const EdgeInsets.only(left: 8),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                    child: Text(
                                  widget.model.title ?? 'Unknown',
                                  maxLines: 5,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 20),
                                )),
                                // Spacer(),
                                Row(children: [
                                  Expanded(
                                      child: Text('${_children.length}页',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18))),
                                  IconButton(
                                      padding: const EdgeInsets.all(4),
                                      iconSize: 32,
                                      onPressed: () {},
                                      icon: const Icon(
                                        Icons.remove_red_eye,
                                        color: Colors.white,
                                      )),
                                  IconButton(
                                      padding: const EdgeInsets.all(4),
                                      iconSize: 32,
                                      onPressed: () {
                                        // DownloadManager();
                                      },
                                      icon: const Icon(
                                        Icons.download,
                                        color: Colors.white,
                                      )),
                                ])
                              ])),
                    )
                  ])),
          Container(
              margin: const EdgeInsets.only(top: 16),
              child: NyaaTags(
                  itemCount: tags.length,
                  builder: (context, index) => NyaaTagItem(text: tags[index])))
        ]));
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).viewPadding.top;
    final tags = _tags.toList();
    return Scaffold(
        // appBar: AppBar(
        //   title: Text(widget.title),
        // ),
        body: RawScrollbar(
      controller: _scrollController,
      thumbColor: Colors.pink[300],
      radius: const Radius.circular(4),
      thickness: 4,
      child: SmartRefresher(
          controller: _refreshController,
          scrollController: _scrollController,
          header: SliverToBoxAdapter(child: buildHeader(statusBarHeight, tags)),
          child: _children.isNotEmpty
              ? MasonryGridView.count(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  crossAxisCount: 3,
                  mainAxisSpacing: 8.0,
                  crossAxisSpacing: 8.0,
                  itemCount: _children.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final controller = AnimationController(
                        value: 1,
                        duration: const Duration(milliseconds: 300),
                        vsync: this);
                    return Material(
                        shadowColor: Colors.black45,
                        //Colors.grey[100],
                        elevation: 2,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(2.0)),
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
                                ExtendedImage.network(getUrl(_children[index]),
                                    headers: _origin.site.headers,
                                    height: 160,
                                    fit: BoxFit.cover,
                                    opacity: controller,
                                    loadStateChanged: (state) {
                                  switch (state.extendedImageLoadState) {
                                    case LoadState.loading:
                                      controller.reset();
                                      return Shimmer.fromColors(
                                          baseColor: const Color.fromRGBO(
                                              240, 240, 240, 1),
                                          highlightColor: Colors.white,
                                          child: AspectRatio(
                                            aspectRatio: 0.8,
                                            child: Container(
                                              decoration: const BoxDecoration(
                                                  color: Colors.white),
                                            ),
                                          ));
                                    case LoadState.failed:
                                      return const AspectRatio(
                                          aspectRatio: 1,
                                          child: Icon(
                                            Icons.image_not_supported,
                                            size: 64,
                                            color: Colors.redAccent,
                                          ));
                                    case LoadState.completed:
                                      controller.forward();
                                      return null;
                                  }
                                }),
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
    ));
  }

  @override
  void dispose() {
    super.dispose();
    _stream?.cancel();
  }
}
