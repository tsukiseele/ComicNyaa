import 'package:comic_nyaa/library/mio/core/mio_loader.dart';
import 'package:comic_nyaa/utils/uri_extensions.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

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
                onPressed: () => onUpdateSubscribe(_subscribes[index]),
                icon: const Icon(Icons.update, color: Colors.black87),
              ),
              onLongPress: () => onDeleteSubscribe(_subscribes[index]),
              onTap: () => onViewSubscibe(_subscribes[index]),
            );
          }),
      floatingActionButton: FloatingActionButton(
          onPressed: onAddSubscribe, child: const Icon(Icons.add, size: 32)),
    );
  }
  
  void onViewSubscibe(Subscribe subscribe) {
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
                Container(
                    margin: const EdgeInsets.only(left: 16),
                    child: const Text("Updating...")),
              ]));
        });
    await SubscribeHolder().addSubscribe(subscribe);
    Fluttertoast.showToast(msg: '规则已更新');
    ns?.pop();
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
                    hintText: "https://hlo.li/static/rules.zip"),
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
                  final name = nameField.text.toString().trim();
                  final url = urlField.text.toString().trim();
                  if (name.isNotEmpty && url.isNotEmpty) {
                    await onUpdateSubscribe(Subscribe(name: name, url: url));
                    ns?.pop();
                    setState(() {});
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
                await SubscribeHolder().removeSubscribe(subscribe);
                ns?.pop();
                setState(() {});
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
