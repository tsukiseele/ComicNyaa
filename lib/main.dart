// import 'dart:convert';

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';

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
    print(filename);
    if (file.isFile) {
      final data = file.content as List<int>;

      final json =  jsonDecode(utf8.decode(data));

      print(json);
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
  String _data = '';

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
    await getRules();
    var httpClient = HttpClient();
    var uri = Uri.http(
        'api.hlo.li', '/music/playlist/detail', {'id': '7490559834'});
    var request = await httpClient.getUrl(uri);
    var response = await request.close();
    var responseBody = await response.transform(const Utf8Decoder()).join();
    setState(()  {
      _data = responseBody;
    });
  }

  @override
  Widget build(BuildContext context) {
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
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Image(image: NetworkImage('https://flutter.github.io/assets-for-api-docs/assets/widgets/owl-2.jpg')),
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter --- $_data',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
