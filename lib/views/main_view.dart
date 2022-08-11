
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:collection/collection.dart';
import 'package:comic_nyaa/views/detail/comic_detail_view.dart';
import 'package:comic_nyaa/views/detail/image_detail_view.dart';
import 'package:comic_nyaa/views/detail/video_detail_view.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

import 'package:comic_nyaa/library/mio/model/site.dart';
import 'package:comic_nyaa/library/mio/core/mio.dart';
import 'package:comic_nyaa/models/typed_model.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../app/global.dart';
import '../models/typed_model.dart';

Future<List<Site>> getRules() async {
  // final savePath = concatPath(ruleDir.path, 'rules.zip');
  // print('savePath: $savePath');
  // await Dio().download('https://hlo.li/static/rules.zip', savePath);

  final sites = <Site>[];
  await for(final file in (await Config.ruleDir).list()) {
    final isAllow = file.path.endsWith('.zip');
    if (isAllow) {
      final bytes = File(file.path).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);
      for (final file in archive) {
        if (file.isFile) {
          final json = jsonDecode(utf8.decode(file.content));
          final jsonMap = Map<String, dynamic>.from(json);
          sites.add(Site.fromJson(jsonMap));
        }
      }
    }
  }
  return sites;
}

class MainView extends StatefulWidget {
  const MainView({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  List<TypedModel> _models = [];
  final Map<int, double> _heightCache = {};
  static const List<String> _kOptions = <String>[
    'aardvark',
    'bobcat',
    'chameleon',
  ];

  Future<List<TypedModel>> _getGallery(Site site) async {
    print('LOAD SITE: ${site.name}');
    final results = await (Mio(site)..setKeywords('')).parseSite();
    final images = List.of(results.map((item) => TypedModel.fromJson(item)));
    return images;
  }

  void _getImagesData() async {
    final sites = await getRules();
    sites.forEachIndexed((i, element) => print('$i: ${element.name}'));
    final site = sites[28];
    final result = await _getGallery(site);
    _heightCache.clear();
    setState(() {
      _models = result;
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
    // setOptimalDisplayMode();
    _getImagesData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(children: [
        DropdownButton(
            value: 'aardvark',
            items: _kOptions.map((e) => DropdownMenuItem<String>(value: e, child: Text(e))).toList(),
            onChanged: (e) {}),
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text == '') {
              return const Iterable<String>.empty();
            }
            return _kOptions.where((String option) {
              return option.contains(textEditingValue.text.toLowerCase());
            });
          },
          onSelected: (String selection) {
            debugPrint('You just selected $selection');
          },
        ),
        Flexible(
            child: MasonryGridView.count(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                crossAxisCount: 3,
                mainAxisSpacing: 8.0,
                crossAxisSpacing: 8.0,
                itemCount: _models.length,
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
        onPressed: _getImagesData,
        tooltip: 'Increment',
        child: const Icon(Icons.refresh),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
