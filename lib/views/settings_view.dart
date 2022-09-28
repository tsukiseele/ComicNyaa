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

import 'package:comic_nyaa/app/app_config.dart';
import 'package:flutter/material.dart';
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
    _downloadPath = (await AppConfig.downloadDir).path;
    setState(() {});
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
            leading: Container(alignment: Alignment.center, width: 32, height: 32, child: const Icon(Icons.cached, color: Colors.black87)) ,
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
    Fluttertoast.showToast(msg: '缓存已清除');
  }
}
