import 'dart:async';
import 'package:comic_nyaa/library/http/nyaa_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'app/config.dart';
import 'library/http/http.dart';
import 'library/mio/core/mio.dart';
import 'views/main_view.dart';

void main() async {
  // LicenseRegistry.addLicense(() async* {
  //   final license = await rootBundle.loadString('google_fonts/OFL.txt');
  //   yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  // });
  // 隐藏状态栏
  // SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
  // 透明状态栏
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(const MaterialApp(home: ComicNyaa()));
  // runApp(const GetMaterialApp(home: ComicNyaa()));
  FlutterNativeSplash.remove();
}

class ComicNyaa extends StatefulWidget {
  const ComicNyaa({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ComicNyaaState();
}

class _ComicNyaaState extends State<ComicNyaa> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Config.appName,
      theme: ThemeData(
        fontFamily: 'ComicNeue',
        primarySwatch: Colors.teal,
      ),
      home: const MainView(title: 'Home'),
    );
  }

  @override
  void initState() {
    // 初始化显示模式
    setOptimalDisplayMode();
    // 初始化Mio
    Mio.setCustomRequest((url, {Map<String, String>? headers}) async {
      /// Http Client
      headers ??= <String, String>{};
      headers['user-agent'] =
          r'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.0.0 Safari/537.36';
      final response = await Http.client.get(Uri.parse(url), headers: headers);
      return response.body;

      /// Dio Client
      // if (headers != null) {
      // headers['user-agent'] = r'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.0.0 Safari/537.36';
      // }
      // final response = await Http.client()
      //     .get(url, options: Options(responseType: ResponseType.plain, headers: headers));
      // return response.data.toString();
      /// Standard Client
      // HttpClientRequest request = await client.getUrl(Uri.parse(url));//.then((HttpClientRequest request) {
      //   headers?.forEach((key, value) => request.headers.add(key, value));
      //   request.headers.add('user-agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.0.0 Safari/537.36');
      // HttpClientResponse response =  await  request.close();
      // return await response.transform(utf8.decoder).join();
    });
    super.initState();
  }

  Future<void> setOptimalDisplayMode() async {
    final List<DisplayMode> supported = await FlutterDisplayMode.supported;
    final DisplayMode active = await FlutterDisplayMode.active;
    final List<DisplayMode> sameResolution = supported
        .where((DisplayMode m) => m.width == active.width && m.height == active.height)
        .toList()
      ..sort((DisplayMode a, DisplayMode b) => b.refreshRate.compareTo(a.refreshRate));

    final DisplayMode mostOptimalMode = sameResolution.isNotEmpty ? sameResolution.first : active;

    /// This setting is per session.
    /// Please ensure this was placed with `initState` of your root widget.
    await FlutterDisplayMode.setPreferredMode(mostOptimalMode);
  }
}
