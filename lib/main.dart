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
import 'dart:convert';
import 'package:comic_nyaa/data/download/nyaa_download_manager.dart';
import 'package:comic_nyaa/data/http_cache_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'app/config.dart';
import 'library/http/http.dart';
import 'library/http/sni.dart' as sni;
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
      title: AppConfig.appName,
      theme: ThemeData(
        fontFamily: 'ComicNeue',
        primarySwatch: Colors.teal,
      ),
      home: const MainView(enableBackControl: true),
      // home: const BackView(child: MainView())
    );
  }

  @override
  void initState() {
    _initialized();
    super.initState();
  }


  void _initialized() {
    // 初始化显示模式
    setOptimalDisplayMode();
    // 初始化Mio
    Mio.setCustomRequest((url, {Map<String, String>? headers}) async {
      // 发送请求 Http Client
      headers ??= <String, String>{};
      // 域前置解析
      url = await sni.parse(url, headers: headers);
      // print('REQUEST::: $url');
      // print('HEADERS::: $headers');
      // 读取缓存
      final cache = await HttpCache.instance.getAsString(url);
      if (cache != null) {
        print('HTTP_CACHE_MANAGER::: READ <<<<<<<<<<<<<<<<< $url');
        return cache;
      }
      final response = await Http.client.get(Uri.parse(url), headers: headers);
      final body = response.body;
      // print('RESPONSE::: $body');
      // 写入缓存
      if (response.statusCode >= 200 && response.statusCode < 300) {
        HttpCache.instance.put(url, response.bodyBytes);
        print('HTTP_CACHE_MANAGER::: WRITE >>>>>>>>>>>>>>>>>>>> $url');
      }
      return body;
    });
    // 初始化下载管理
    NyaaDownloadManager.instance;
  }

  Future<void> setOptimalDisplayMode() async {
    final List<DisplayMode> supported = await FlutterDisplayMode.supported;
    final DisplayMode active = await FlutterDisplayMode.active;
    final List<DisplayMode> sameResolution = supported
        .where((DisplayMode m) =>
            m.width == active.width && m.height == active.height)
        .toList()
      ..sort((DisplayMode a, DisplayMode b) =>
          b.refreshRate.compareTo(a.refreshRate));

    final DisplayMode mostOptimalMode =
        sameResolution.isNotEmpty ? sameResolution.first : active;

    /// This setting is per session.
    /// Please ensure this was placed with `initState` of your root widget.
    await FlutterDisplayMode.setPreferredMode(mostOptimalMode);
  }
}
