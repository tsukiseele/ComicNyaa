import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SubscribeView extends StatefulWidget {
  const SubscribeView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SubscribeViewState();
}

class _SubscribeViewState extends State<SubscribeView> {
  final List<String> _subscribes = ['https://hlo.li/static/rules.zip'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('订阅')),
        body: Container(
            child: ListView.builder(
                itemCount: _subscribes.length,
                itemBuilder: (ctx, index) {
                  return ListTile(title: Text(_subscribes[index]));
                })));
  }
}
