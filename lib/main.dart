// import 'dart:convert';

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
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';

String concatPath(dirname, filename) {
  return '$dirname${Platform.pathSeparator}$filename';
}

Future<List<Site>> getRules() async {
  final appDir = await getApplicationDocumentsDirectory();
  final ruleDir =
      await Directory(concatPath(appDir.path, 'rules')).create(recursive: true);
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
  final results = await Mio(site).parseSite();
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
  int _counter = 0;
  List<MImage> _data = [];

  void _incrementCounter() {
    setState(() {
      _counter++;
      getData();
    });
  }

  void getData() async {
    final sites = await getRules();
    sites.forEachIndexed((i, element) => print('$i: ${element.name}'));
    final site = sites[22];
    final result = await getGallery(site);
    setState(() {
      _data = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        padding: const EdgeInsets.all(8.0),
        child: MasonryGridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 8.0,
            crossAxisSpacing: 8.0,
            itemCount: _data.length,
            itemBuilder: (context, index) {
              return Material(
                  elevation: 4.0,
                  borderRadius: const BorderRadius.all(Radius.circular(0.0)),
                  child: Column(
                    children: [
                      CachedNetworkImage(
                        placeholder: (context, url) =>
                            const CircularProgressIndicator(),
                        imageUrl: _data[index].coverUrl ?? '',
                      ),
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(_data[index].title ?? ''),
                      )
                    ],
                  ));
            }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
