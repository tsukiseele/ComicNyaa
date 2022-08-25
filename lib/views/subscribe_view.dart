import 'dart:io';

import 'package:comic_nyaa/library/mio/core/mio_loader.dart';
import 'package:comic_nyaa/utils/uri_extensions.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

import '../data/subscribe_holder.dart';

class SubscribeView extends StatefulWidget {
  const SubscribeView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SubscribeViewState();
}

class _SubscribeViewState extends State<SubscribeView> {
  final List<Subscribe> _subscribes = SubscribeHolder().subscribes;

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
                  await SubscribeHolder().updateSubscribe(_subscribes[index]);
                  Fluttertoast.showToast(msg: '规则已更新');
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
                                      subtitle:
                                          Text(sites[index].details ?? '')))));
                    });
              },
            );
          }),
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            showDialog(
                context: context,
                builder: (ctx) {
                  final nameField = TextEditingController();
                  final urlField = TextEditingController();

                  return AlertDialog(
                      alignment: Alignment.center,
                      title: const Text('添加订阅'),
                      content:
                          // height: 384,
                          // width: double.maxFinite,
                          Material(
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                            TextFormField(
                              controller: nameField,
                              decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.all(10.0),
                                  icon: Icon(Icons.nature_people),
                                  labelText: "请输入订阅名",
//                  hintText: "fdsfdss",
                                  helperText: "订阅名"),
                            ),
                            TextFormField(
                              controller: urlField,
                              decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.all(10.0),
                                  icon: Icon(Icons.nature_people),
                                  labelText: "请输入订阅链接",
//                  hintText: "fdsfdss",
                                  helperText: "订阅链接"),
                            ),
                            Builder(builder: (BuildContext context) {
                              return ElevatedButton(
                                onPressed: () {
                                  if (nameField.text.toString().trim().isNotEmpty
                                           &&
                                      urlField.text.toString().trim().isNotEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        new SnackBar(
                                            content: new Text("不能为空")));
                                  } else {
                                    SubscribeHolder.
                                  }
                                },
                                color: Colors.blue,
                                highlightColor: Colors.deepPurple,
                                disabledColor: Colors.cyan,
                                child: new Text(
                                  "登录",
                                  style: new TextStyle(color: Colors.white),
                                ),
                              );
                            })
                          ])));
                });
          },
          child: const Icon(Icons.add, size: 32)),
    );
  }
}
