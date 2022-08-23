import 'dart:io';

import 'package:comic_nyaa/library/mio/core/mio_loader.dart';
import 'package:comic_nyaa/utils/uri_extensions.dart';
import 'package:flutter/material.dart';

import '../app/global.dart';
import '../data/subscribe_holder.dart';
import '../utils/http.dart';

class SubscribeView extends StatefulWidget {
  const SubscribeView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SubscribeViewState();
}

class _SubscribeViewState extends State<SubscribeView> {
  final List<Subscribe> _subscribes = SubscribeHolder().subscribes;

  Future<void> _updateSubscribe(String url) async {
    final dir = await Config.ruleDir;
    final savePath = dir.join(Uri.parse(url).filename).path;
    await Http.client().download(url, savePath);
    await RuleLoader.loadFormDirectory(dir);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('订阅')),
        body: ListView.builder(
            itemCount: _subscribes.length,
            itemBuilder: (ctx, index) {
              return ListTile(
                leading: Icon(
                  Icons.subscript,
                  color: Theme.of(context).primaryColor,
                  size: 32,
                ),
                title: Text(_subscribes[index].name),
                subtitle: Text(_subscribes[index].url),
                trailing: IconButton(
                  onPressed: () async {
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
                                Container(
                                    margin: const EdgeInsets.only(left: 16),
                                    child: const Text("Updating...")),
                              ]));
                        });
                    await _updateSubscribe(_subscribes[index].url);
                    ns?.pop();
                  },
                  icon: const Icon(Icons.update, color: Colors.black87),
                ),
                onTap: () {
                  final subscribe = _subscribes[index];
                  final path = RuleLoader.targetInfo.keys.singleWhere((path) =>
                      Uri.parse(subscribe.url).filename ==
                      Uri.parse(path).filename);
                  final sites = RuleLoader.targetInfo[path] ?? [];
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
                                    itemBuilder: (ctx, index) => ListTile(
                                        title: Text(sites[index].name ?? ''),
                                        subtitle: Text(
                                            sites[index].details ?? '')))));
                      });
                },
              );
            }));
  }
}
