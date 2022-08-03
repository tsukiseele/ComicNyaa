// import 'dart:convert';

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter/cupertino.dart';

String concatPath(dirname , filename) {
  return '$dirname${Platform.pathSeparator}$filename';
}
Future<void> getRules() async {
  // var rs = await Dio().get('https://hlo.li/static/rules.zip',
  //     options: Options(responseType: ResponseType.bytes));
  final appDir = await getApplicationDocumentsDirectory();
  final ruleDir  = await Directory(concatPath(appDir.path, 'rules')).create(recursive: true);
  final savePath = concatPath(ruleDir.path, 'rules.zip');
  print('savePath: $savePath');
  final rs = await Dio().download('https://hlo.li/static/rules.zip', savePath);
  final bytes = File(savePath).readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(bytes);

  for (final file in archive) {
    final filename = file.name;
    // print(filename);
    if (file.isFile) {
      final data = file.content as List<int>;

      final json =  jsonDecode(utf8.decode(data));

      // print(json);
      // File('out/' + filename)
      //   ..createSync(recursive: true)
      //   ..writeAsBytesSync(data);
    } else {
      // Directory('out/' + filename).create(recursive: true);
    }
  }
}
// Future<String> loadAsset() async {
//   // return await rootBundle.loadStructuredData('assets/config.json');
// }
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);


  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  List<String> _data= [];

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
      getData();
    });
  }
  void getData() async {
    // await getRules();
    var httpClient = HttpClient();
    var uri = Uri.http(
        'api.hlo.li', '/music/playlist/detail', {'id': '7490559834'});
    var request = await httpClient.getUrl(uri);
    var response = await request.close();
    print('YYYYYYYY');
    Map<String, dynamic> responseBody = jsonDecode(await response.transform(const Utf8Decoder()).join());
    print('XXXXXXXXXXXXXXX');
    // print(responseBody);
    // responseBody
    var list = responseBody['playlist']['tracks'] as List<dynamic>;
    // print('LIST: ' + list.toString());
    // final result = list.map((key, value) => {
    //   MapEntry(key, value['al']['picUrl']);
    //     }).values as List<String>;
    final d = list.map((value) {
      print('=======================');
      print(value['al']['picUrl']);
      return value['al']['picUrl'];
    }).cast<String>();
    setState(() {
      _data = d.toList();
    });
  } 


  @override
  Widget build(BuildContext context) {

    // getData();
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.


    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body:
          MasonryGridView.count(crossAxisCount: 4,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            itemBuilder: (context, index) {
              return Material(
                // index: index,
                // extent: (index % 5 + 1) * 100,
                elevation: 8.0,
                borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                child: CachedNetworkImage(
                  imageUrl: "https://gimg2.baidu.com/image_search/src=http%3A%2F%2Fimg1.yuntouxiang.com%2Fuploads%2F20130521%2F21-022304_646.jpg&refer=http%3A%2F%2Fimg1.yuntouxiang.com&app=2002&size=f9999,10000&q=a80&n=0&g=0n&fmt=jpeg?sec=1613615452&t=590bdef8fdbfb5c972066acbeca6543d",
                  imageBuilder: (context, imageProvider) =>
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(
                              Radius.circular(8.0)),
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.fitHeight,
                          ),
                        ),
                      ),
                ),
              );
            }
            // ListView.builder(
            //   itemCount: _data.length,
            //   itemBuilder: (context, index) {
            //     return ListTile(
            //       leading: Image(image: NetworkImage(_data[index])),
            //       trailing: const Icon(Icons.shopping_cart),
            //       title: Text(_data[index]),
            //     );
            //   },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

// class Tile extends Widget {
//   @override
//   Element createElement() {
//     // TODO: implement createElement
//     throw UnimplementedError();
//   }
// }
