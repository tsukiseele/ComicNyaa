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

import 'package:flutter/material.dart';

import '../../app/config.dart';
import '../../library/mio/model/site.dart';
import '../../utils/flutter_utils.dart';
import '../../widget/simple_network_image.dart';
import '../download_view.dart';
import '../settings_view.dart';
import '../subscribe_view.dart';

class NyaaDrawer extends StatelessWidget {
  const NyaaDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: ListView(padding: EdgeInsets.zero, children: [
      Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Material(
              elevation: 4,
              child: Stack(children: [
                const SimpleNetworkImage(
                  'https://cdn.jsdelivr.net/gh/nyarray/LoliHost/images/94d6d0e7be187770e5d538539d95a12a.jpeg',
                  fit: BoxFit.cover,
                  width: double.maxFinite,
                  height: 160 + kToolbarHeight,
                ),
                Positioned.fill(
                  child: Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          gradient: LinearGradient(
                              begin: FractionalOffset.topCenter,
                              end: FractionalOffset.bottomCenter,
                              colors: [
                                Colors.grey.withOpacity(0.0),
                                Colors.black45,
                              ],
                              stops: const [
                                0.0,
                                1.0
                              ])),
                      padding: const EdgeInsets.all(8),
                      alignment: Alignment.bottomLeft,
                      child: Text(
                          "Os iustī meditabitur sapientiam, Et lingua eius loquetur iudicium.",
                          style: TextStyle(
                              color: Colors.teal[200],
                              fontSize: 18,
                              // fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(color: Colors.teal[100]!, blurRadius: 8)
                              ]))),
                ),
              ]))),
      ListTile(
          title: const Text('主页'),
          selected: true,
          selectedTileColor: const Color.fromRGBO(0, 127, 127, .2),
          onTap: () {},
          iconColor: Colors.teal,
          leading: const Icon(Icons.home)),
      ListTile(
          title: const Text('订阅'),
          onTap: () => RouteUtil.push(context, const SubscribeView()),
          iconColor: Colors.black87,
          leading: const Icon(Icons.collections_bookmark)),
      ListTile(
          title: const Text('下载'),
          onTap: () => RouteUtil.push(context, const DownloadView()),
          iconColor: Colors.black87,
          leading: const Icon(Icons.download)),
      ListTile(
          title: const Text('设置'),
          onTap: () => RouteUtil.push(context, const SettingsView()),
          iconColor: Colors.black87,
          leading: const Icon(Icons.tune))
    ]));
  }

  Widget _buildHeader() {
    return const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Material(
            elevation: 4,
            child: SimpleNetworkImage(
              'https://cdn.jsdelivr.net/gh/nyarray/LoliHost/images/7c4f1d7ea2dadd3ca835b9b2b9219681.webp',
              fit: BoxFit.cover,
              height: 160 + kToolbarHeight,
            )));
  }
}
