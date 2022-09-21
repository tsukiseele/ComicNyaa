/*
 * Copyright (C) 2022. TsukiSeele
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:comic_nyaa/library/mio/core/mio.dart';
import 'package:comic_nyaa/library/mio/model/data_origin.dart';
import 'package:comic_nyaa/models/typed_model.dart';
import 'package:comic_nyaa/utils/extensions.dart';
import 'package:comic_nyaa/utils/flutter_utils.dart';
import 'package:comic_nyaa/views/detail/image_detail_view.dart';
import 'package:comic_nyaa/widget/nyaa_tag_item.dart';
import 'package:comic_nyaa/widget/nyaa_tags.dart';
import 'package:comic_nyaa/widget/ink_stack.dart';
import 'package:comic_nyaa/widget/simple_network_image.dart';
import 'package:comic_nyaa/data/download/nyaa_download_manager.dart';
import 'package:comic_nyaa/views/main_view.dart';

class ComicDetailView extends StatefulWidget {
  const ComicDetailView({Key? key, required this.model, required this.heroKey}) : super(key: key);
  final title = '漫画';
  final String heroKey;
  final TypedModel model;

  @override
  State<StatefulWidget> createState() {
    return _ComicDetailViewState();
  }
}

class _ComicDetailViewState extends State<ComicDetailView> with TickerProviderStateMixin {
  final RefreshController _refreshController = RefreshController();
  final ScrollController _scrollController = ScrollController();
  final List<TypedModel> _children = [];
  final Set<String> _tags = {};
  late TypedModel _model;
  late DataOrigin _origin;
  StreamSubscription<List<Map<String, dynamic>>>? _stream;

  void _initialized() async {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent) {
        while (_stream?.isPaused == true) {
          _stream?.resume();
        }
      }
    });
    _model = widget.model;
    _origin = _model.getOrigin();
    _tags.addAll(_model.tags?.split(' ').toSet() ?? {});
    final json = _model.toJson();
    //
    _stream = Mio(_origin.site).parseChildren(item: json).listen((List<Map<String, dynamic>> data) {
      _stream?.pause();
      _getNext(data);
    });
    _model = TypedModel.fromJson(await Mio(_origin.site).parseExtended(item: json));
    setState(() {});
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

  @override
  void initState() {
    _initialized();
    super.initState();
  }

  Widget _buildHeader(double statusBarHeight, List<String> tags) {
    return Column(children: [
      Material(
          elevation: 4,
          child: Container(
              color: Theme.of(context).primaryColor.withOpacity(.667),
              padding: EdgeInsets.only(top: statusBarHeight + 8, bottom: 0, left: 0, right: 0),
              child: SizedBox(
                  height: 192,
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      alignment: Alignment.center,
                      child: Material(
                        color: Colors.transparent,
                        shadowColor: Colors.black45,
                        elevation: 4,
                        child: Hero(
                            tag: widget.heroKey,
                            child: SimpleNetworkImage(
                             _model.availableCoverUrl,
                              width: 120,
                              headers: _origin.site.headers,
                              disableAnimation: true,
                            )),
                      ),
                    ),
                    Expanded(
                      child: Container(
                          margin: const EdgeInsets.only(left: 8, top: 8),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                            Expanded(
                                child: Text(
                              _model.title ?? 'Unknown',
                              maxLines: 5,
                              style: const TextStyle(color: Colors.white, fontSize: 20),
                            )),
                            // Spacer(),
                            Row(children: [
                              Expanded(
                                  child:
                                      Text('${_children.length}页', style: const TextStyle(color: Colors.white, fontSize: 18))),
                              IconButton(
                                  padding: const EdgeInsets.all(4),
                                  iconSize: 32,
                                  onPressed: () {
                                    RouteUtil.push(
                                        context, ImageDetailView(models: _children, heroKey: widget.heroKey, index: 0));
                                  },
                                  icon: const Icon(
                                    Icons.remove_red_eye,
                                    color: Colors.white,
                                  )),
                              IconButton(
                                  padding: const EdgeInsets.all(4),
                                  iconSize: 32,
                                  onPressed: () async {
                                    (await NyaaDownloadManager.instance).add(_model);
                                    Fluttertoast.showToast(msg: '下载已添加：${_model.title}');
                                  },
                                  icon: const Icon(
                                    Icons.download,
                                    color: Colors.white,
                                  )),
                            ])
                          ])),
                    )
                  ])))),
      Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.only(bottom: 8),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black12))),
          child: Column(children: [
            NyaaTags(
                itemCount: tags.length,
                builder: (context, index) => NyaaTagItem(
                      text: tags[index],
                      color: Colors.teal,
                      onTap: () {
                        RouteUtil.push(context, MainView(site: _model.getOrigin().site, keywords: tags[index]));
                      },
                    ))
          ]))
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).viewPadding.top;
    final tags = _tags.toList();
    return Scaffold(
        body: RawScrollbar(
      controller: _scrollController,
      thumbColor: Colors.pink[200],
      radius: const Radius.circular(4),
      thickness: 4,
      child: SmartRefresher(
          controller: _refreshController,
          scrollController: _scrollController,
          header: SliverToBoxAdapter(child: _buildHeader(statusBarHeight, tags)),
          child: _children.isNotEmpty
              ? MasonryGridView.count(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  crossAxisCount: 3,
                  mainAxisSpacing: 8.0,
                  crossAxisSpacing: 8.0,
                  itemCount: _children.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final imageUrl = _children[index].availableCoverUrl;
                    // print('CURL: $imageUrl');
                    return Material(
                        shadowColor: Colors.black45,
                        elevation: 2,
                        borderRadius: const BorderRadius.all(Radius.circular(2.0)),
                        child: InkStack(
                            onTap: () => RouteUtil.push(
                                context,
                                ImageDetailView(
                                  models: _children,
                                  heroKey: widget.heroKey,
                                  index: index,
                                )),
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Hero(
                                    tag: '${widget.heroKey}-$imageUrl-$index',
                                    child: SimpleNetworkImage(
                                      imageUrl,
                                      headers: _origin.site.headers,
                                      height: 160,
                                      // width: double.maxFinite,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(_children[index].title ?? ''),
                                  )
                                ],
                              )
                            ]));
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
