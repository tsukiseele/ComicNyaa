import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:comic_nyaa/lib/mio/core/doc_handler.dart';
import 'package:comic_nyaa/lib/mio/model/meta.dart';
import 'package:comic_nyaa/lib/mio/model/site.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';

String concatPath(dirname, filename) {
  return '$dirname${Platform.pathSeparator}$filename';
}

Future<List<Site>> getRules() async {
  final appDir = await getApplicationDocumentsDirectory();
  final ruleDir = await Directory(concatPath(appDir.path, 'rules')).create(recursive: true);
  final savePath = concatPath(ruleDir.path, 'rules.zip');
  print('savePath: $savePath');
  await Dio().download('https://hlo.li/static/rules.zip', savePath);
  // 读取规则
  final bytes = File(savePath).readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(bytes);
  final sites = <Site>[];
  for (final file in archive) {
    if (file.isFile) {
      final data = file.content as List<int>;
      final json = jsonDecode(utf8.decode(data));
      final map = Map<String, dynamic>.from(json);
      final site = Site.fromJson(map);
      sites.add(site);
    }
  }
  return sites;
}

// Future<String> loadAsset() async {
//   // return await rootBundle.loadStructuredData('assets/config.json');
// }
void main() async {
  runApp(const ComicNyaa());
}

class ComicNyaa extends StatelessWidget {
  const ComicNyaa({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ComicNyaa',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: const HomePage(title: 'Home'),
    );
  }
}

Future<List<MImage>> getGallery(site) async {
  print('LOAD SITE: ${site.name}');
  final results = await Mio(site).setKeywords('').parseSite();
  final images = List.of(results.map((item) => MImage.fromJson(item)));
  for (var image in images) {
    print(image.title);
    print(image.coverUrl);
  }
  print('PARSE RESULTS: $images');
  return images;
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<MImage> _images = [];
  static const List<String> _kOptions = <String>[
    'aardvark',
    'bobcat',
    'chameleon',
  ];

  void _getImagesData() async {
    final sites = await getRules();
    sites.forEachIndexed((i, element) => print('$i: ${element.name}'));
    final site = sites[9];
    final result = await getGallery(site);
    setState(() {
      _images = result;
    });
  }

  @override
  void initState() {
    setOptimalDisplayMode();
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
                itemCount: _images.length,
                itemBuilder: (context, index) {
                  return Material(
                      elevation: 2.0,
                      borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                      child: InkWell(
                          onTap: () {},
                          child: Column(
                            children: [
                              CachedNetworkImage(
                                placeholder: (context, url) => const CircularProgressIndicator(),
                                imageUrl: _images[index].coverUrl ?? '',
                              ),
                              Container(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(_images[index].title ?? ''),
                              )
                            ],
                          )));
                }))
      ]),
      // ]),
      floatingActionButton: FloatingActionButton(
        onPressed: _getImagesData,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Future<void> setOptimalDisplayMode() async {
    final List<DisplayMode> supported = await FlutterDisplayMode.supported;
    final DisplayMode active = await FlutterDisplayMode.active;

    final List<DisplayMode> sameResolution = supported.where((DisplayMode m) => m.width == active.width && m.height == active.height).toList()..sort((DisplayMode a, DisplayMode b) => b.refreshRate.compareTo(a.refreshRate));

    final DisplayMode mostOptimalMode = sameResolution.isNotEmpty ? sameResolution.first : active;

    /// This setting is per session.
    /// Please ensure this was placed with `initState` of your root widget.
    await FlutterDisplayMode.setPreferredMode(mostOptimalMode);
  }
}
