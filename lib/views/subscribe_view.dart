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

import 'dart:math';

import 'package:comic_nyaa/data/subscribe/subscribe_manager.dart';
import 'package:comic_nyaa/data/subscribe/subscribe_provider.dart';
import 'package:comic_nyaa/library/mio/core/site_manager.dart';
import 'package:comic_nyaa/utils/uri_extensions.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../data/subscribe/subscribe_provider.dart';

class SubscribeView extends StatefulWidget {
  const SubscribeView({Key? key}) : super(key: key);

  @override
  State<SubscribeView> createState() => _SubscribeViewState();
}

class _SubscribeViewState extends State<SubscribeView> {
  List<Subscribe> _subscribes = [];

  @override
  void initState() {
    super.initState();
    _update();
  }

  Future<void> _update() async {
    final subscribes = await (await SubscribeManager.instance).subscribes;
    setState(() => _subscribes = subscribes);
    print('SUBSCRIBE::: $_subscribes');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('订阅')),
      body: ListView.builder(
          itemCount: _subscribes.length,
          itemBuilder: (ctx, index) {
            return ListTile(
              contentPadding: const EdgeInsets.all(8),
              leading: Icon(
                Icons.subscript,
                color: Theme.of(context).primaryColor,
                size: 32,
              ),
              title: Text(_subscribes[index].name ?? ''),
              subtitle: Text(_subscribes[index].url ?? ''),
              trailing: IconButton(
                onPressed: () => onUpdateSubscribe(_subscribes[index]),
                icon: const Icon(Icons.update, color: Colors.black87),
              ),
              onLongPress: () => onDeleteSubscribe(_subscribes[index]),
              onTap: () => onViewSubscibe(_subscribes[index]),
            );
          }),
      floatingActionButton: FloatingActionButton(onPressed: onAddSubscribe, child: const Icon(Icons.add, size: 32)),
    );
  }

  void onViewSubscibe(Subscribe subscribe) {
    final path =
        SiteManager.targetInfo.keys.singleWhere((path) => Uri.parse(subscribe.url!).filename == Uri.parse(path).filename);
    final sites = SiteManager.targetInfo[path] ?? [];
    print('SITE COUNT: ${sites.length}');
    showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
              title: const Text('该订阅包含如下规则'),
              content: SizedBox(
                  height: 384,
                  width: double.maxFinite,
                  child: ListView.builder(
                      itemCount: sites.length,
                      itemBuilder: (ctx, index) =>
                          ListTile(title: Text(sites[index].name ?? ''), subtitle: Text(sites[index].details ?? '')))));
        });
  }

  Future<void> onUpdateSubscribe(Subscribe subscribe) async {
    NavigatorState? ns;
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          ns = Navigator.of(ctx);
          return AlertDialog(
              title: const Text('正在更新订阅'),
              content: Row(children: [
                const CircularProgressIndicator(),
                Container(margin: const EdgeInsets.only(left: 16), child: const Text("Updating...")),
              ]));
        });
    try {
      await (await SubscribeManager.instance).updateSubscribe(subscribe);
      Fluttertoast.showToast(msg: '规则已更新');
    } catch (e) {
      print(e);
      Fluttertoast.showToast(msg: '更新失败');
    } finally {
      ns?.pop();
    }
  }

  void onAddSubscribe() {
    NavigatorState? ns;
    showDialog(
        context: context,
        builder: (ctx) {
          ns = Navigator.of(ctx);
          final nameField = TextEditingController();
          final urlField = TextEditingController();
          return AlertDialog(
            alignment: Alignment.center,
            title: const Text('添加订阅'),
            content: Material(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: nameField,
                decoration: const InputDecoration(
                    // contentPadding: EdgeInsets.all(10.0),
                    icon: Icon(Icons.label_outline),
                    labelText: "订阅名",
                    hintText: "New Subscribe"),
              ),
              TextFormField(
                controller: urlField,
                decoration: const InputDecoration(
                    // contentPadding: EdgeInsets.all(10.0),
                    icon: Icon(Icons.link),
                    labelText: "订阅链接",
                    hintText: "https://xxx.xxx/xxx.zip"),
              )
            ])),
            actions: [
              TextButton(
                onPressed: () => ns?.pop(),
                child: const Text(
                  "取消",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () async {
                  var name = nameField.text.toString().trim();
                  var url = urlField.text.toString().trim();
                  if (name.isEmpty) {
                    name = 'New Subscribe';
                  }
                  if (url.isNotEmpty) {
                    final subscribe = Subscribe(name: name, url: url, updateDate: DateTime.now().toIso8601String(), version: 1);
                    (await SubscribeManager.instance).addSubscribe(subscribe);
                    await onUpdateSubscribe(subscribe);
                    ns?.pop();
                    setState(() => _update());
                  } else {
                    Fluttertoast.showToast(msg: "订阅信息不能为空");
                  }
                },
                child: Text(
                  "添加",
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ),
            ],
          );
        });
  }

  void onDeleteSubscribe(Subscribe subscribe) {
    NavigatorState? ns;
    showDialog(
        context: context,
        builder: (ctx) {
          ns = Navigator.of(ctx);
          return AlertDialog(title: Text('确定删除${subscribe.name}？'), actions: [
            TextButton(
              onPressed: () => ns?.pop(),
              child: const Text(
                "取消",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                await (await SubscribeManager.instance).deleteSubscribe(subscribe);
                ns?.pop();
                setState(() => _update());
              },
              child: Text(
                "确定",
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
          ]);
        });
  }
}
