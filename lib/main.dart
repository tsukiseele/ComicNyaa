import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:comic_nyaa/app/constant.dart';
import 'package:comic_nyaa/library/mio/core/mio_loader.dart';
import 'package:comic_nyaa/utils/http.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'app/global.dart';
import 'library/mio/core/mio.dart';
import 'views/main_view.dart';

void main() async {
  // LicenseRegistry.addLicense(() async* {
  //   final license = await rootBundle.loadString('google_fonts/OFL.txt');
  //   yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  // });
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(const ComicNyaa());
  FlutterNativeSplash.remove();
}

class ComicNyaa extends StatefulWidget {
  const ComicNyaa({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ComicNyaaState();
}

class _ComicNyaaState extends State<ComicNyaa> {

  final HttpClient client = HttpClient();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Constant.appName,
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
    client.maxConnectionsPerHost = 3;
    Mio.setCustomRequest((url, {Map<String, String>? headers}) async {
      if (headers != null) {
        headers['user-agent'] = r'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.0.0 Safari/537.36';
      }
      final response = await Http.client()
          .get(url, options: Options(responseType: ResponseType.plain, headers: headers));
      return response.data.toString();
    //   HttpClientRequest request = await client.getUrl(Uri.parse(url));//.then((HttpClientRequest request) {
    //     headers?.forEach((key, value) => request.headers.add(key, value));
    //     request.headers.add('user-agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.0.0 Safari/537.36');
    //   HttpClientResponse response =  await  request.close();
    //   return await response.transform(utf8.decoder).join();
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
