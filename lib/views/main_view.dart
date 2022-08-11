import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive.dart';
import 'package:collection/collection.dart';
import 'package:comic_nyaa/library/mio/core/mio_loader.dart';
import 'package:comic_nyaa/views/detail/comic_detail_view.dart';
import 'package:comic_nyaa/views/detail/image_detail_view.dart';
import 'package:comic_nyaa/views/detail/video_detail_view.dart';
import 'package:dio/dio.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

import 'package:comic_nyaa/library/mio/model/site.dart';
import 'package:comic_nyaa/library/mio/core/mio.dart';
import 'package:comic_nyaa/models/typed_model.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../app/global.dart';
import '../models/typed_model.dart';

class MainView extends StatefulWidget {
  const MainView({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, double> _heightCache = {};
  List<TypedModel> _models = [];
  List<Site> _sites = [];
  int _currentSiteId = 920;
  int _page = 1;
  String _keywords = '';
  bool _isLoading = false;

  Future<List<TypedModel>> _getModels() async {
    _isLoading = true;
    try {
      final results = await (Mio(_sites.firstWhere((site) => site.id == _currentSiteId, orElse: () => _sites[0]))
            ..setPage(_page)
            ..setKeywords(_keywords))
          .parseSite();
      final images = List.of(results.map((item) => TypedModel.fromJson(item)));
      return images;
    } catch (e) {
      rethrow;
      // print('LOAD ERROR: $e');
    } finally {
      _isLoading = false;
    }
    return [];
  }

  Future<List<TypedModel>> _getNext() async {
    ++_page;
    final models = await _getModels();
    setState(() => _models.addAll(models));
    return models;
  }

  Future<List<TypedModel>> _onSearch(String keywords) async {
    setState(() {
      _models.clear();
      _heightCache.clear();
    });
    _page = 1;
    _keywords = keywords;
    final models = await _getModels();
    setState(() => _models = models);
    return models;
  }

  Future<void> _updateSubscribe() async {
    final savePath = (await Config.ruleDir).concatPath('rules.zip').path;
    print('savePath: $savePath');
    await Dio().download('https://hlo.li/static/rules.zip', savePath);
  }

  Future<void> _initialize() async {
    _updateSubscribe();

    final sites = await RuleLoader.getRules(await Config.ruleDir);
    sites.forEachIndexed((i, element) => print('$i: [${element.id}]${element.name}'));
    setState(() {
      _sites = sites;
      _currentSiteId = _currentSiteId < 0 ? _sites[0].id! : _currentSiteId;
    });
    final models = await _getModels();
    setState(() => _models = models);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent) {
        if (!_isLoading) {
          _getNext();
        }
      }
    });
  }

  void _jump(TypedModel model) {
    Widget? target;
    switch (model.type) {
      case 'image':
        target = ImageDetailView(model: model);
        break;
      case 'video':
        target = VideoDetailView(model: model);
        break;
      case 'comic':
        target = ComicDetailView(model: model);
        break;
    }
    if (target != null) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => target!));
    }
  }

  @override
  void initState() {
    _initialize();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(children: [
        Container(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: Row(
              children: [
                DropdownButton(
                    value: _currentSiteId,
                    items: _sites.map((e) => DropdownMenuItem<int>(value: e.id, child: Text(e.name ?? 'unknown'))).toList(),
                    onChanged: (int? value) {
                      print('SELECT ${value}');
                      setState(() => _currentSiteId = value!);
                    }),
                // DropdownButtonFormField(items: items, onChanged: onChanged)
                ElevatedButton(onPressed: () => _onSearch(''), child: const Text('搜索'))
              ],
            )),
        Flexible(
            child: MasonryGridView.count(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                crossAxisCount: 3,
                mainAxisSpacing: 8.0,
                crossAxisSpacing: 8.0,
                itemCount: _models.length,
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return Material(
                      elevation: 2.0,
                      borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                      child: InkWell(
                          onTap: () => _jump(_models[index]),
                          child: Column(
                            children: [
                              ExtendedImage.network(
                                _models[index].coverUrl ?? '',
                                height: _heightCache[index],
                                afterPaintImage: (canvas, rect, image, paint) {
                                  if (_heightCache[index] == null) _heightCache[index] = rect.height;
                                },
                              ),
                              Container(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(_models[index].title ?? ''),
                              )
                            ],
                          )));
                }))
      ]),
      // ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _getNext(),
        tooltip: 'Increment',
        child: const Icon(Icons.refresh),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
