import 'dart:isolate';

import 'package:comic_nyaa/app/global.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart' as cache;
import 'package:fluttertoast/fluttertoast.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SettingsViewState();
  }
}

class _SettingsViewState extends State<StatefulWidget> {
  String _downloadPath = '';

  initialized() async {
    _downloadPath = (await Config.downloadDir).path;
  }
  @override
  void initState() {
    super.initState();
    initialized();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(children: [
        ListTile(
            leading: Container(alignment: Alignment.center, width: 32, height: 32, child: Icon(Icons.cached, color: Colors.black87)) ,
            title: const Text('缓存'),
            subtitle: const Text('清除缓存'),
            onTap: () {
              _clearCache();
            }),
        ListTile(
            leading: const Icon(Icons.download, color: Colors.black87),
            title: const Text('下载位置'),
            subtitle: Text(_downloadPath),
            onTap: () {
              // DefaultCacheManager().emptyCache();
              // Fluttertoast.showToast(msg: '清除成功');
            })
      ]),
    );
  }

  static void _clearCache() async {
    await cache.DefaultCacheManager().emptyCache();
    Fluttertoast.showToast(msg: '缓存已清除');
  }
}