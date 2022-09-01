import 'dart:async';

import 'package:comic_nyaa/data/download/nyaa_download_manager.dart';
import 'package:comic_nyaa/library/download/download_task_queue.dart';
import 'package:flutter/material.dart';

import '../data/download/nyaa_download_task_queue.dart';

class DownloadView extends StatefulWidget {
  const DownloadView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _DownloadViewState();
  }
}

class _DownloadViewState extends State<DownloadView> {
  late List<NyaaDownloadTaskQueue> _downloadList;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    loopUpdateStatus();
  }

  void loopUpdateStatus() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    _downloadList = NyaaDownloadManager.instance.tasks;
    return Scaffold(
      appBar: AppBar(title: const Text('下载')),
      body: Material(
          child: ListView(
        children: List.generate(_downloadList.length, (index) {
          final queue = _downloadList[index];
          String title = queue.name;
          // if (queue.isSingle()) {
          //   title = queue.name;
          // } else {
          //
          // }
          return ListTile(
              title: Text(title), subtitle: Text(queue.status.toString()));
        }),
      )),
    );
  }
}
