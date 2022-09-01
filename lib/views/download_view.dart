import 'package:flutter/material.dart';

class DownloadView extends StatefulWidget {
  const DownloadView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _DownloadViewState();
  }

}

class _DownloadViewState extends State<DownloadView> {
  final _downloadList = [];

  @override
  void initState() {
    super.initState();
    // _downloadList =
  }

  @override
  Widget build(BuildContext context) {
    return Material(child: ListView(children: List.generate(_downloadList.length, (index) => ListTile()),));
  }
}