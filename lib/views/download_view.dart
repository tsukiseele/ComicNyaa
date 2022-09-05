import 'dart:async';

import 'package:comic_nyaa/data/download/nyaa_download_manager.dart';
import 'package:comic_nyaa/widget/simple_network_image.dart';
import 'package:flutter/material.dart';

import '../data/download/nyaa_download_task_queue.dart';

class DownloadView extends StatefulWidget {
  const DownloadView(
      {Key? key, this.updateInterval = const Duration(milliseconds: 500)})
      : super(key: key);
  final Duration updateInterval;

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
    _timer = Timer.periodic(widget.updateInterval, (timer) => setState(() {}));
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
          String title = queue.title;
          return ListTile(
              leading: SimpleNetworkImage(
                queue.cover,
                headers: queue.headers,
                width: 48,
                height: 48,
              ),
              title: Text(title),
              subtitle: Text(
                  '${queue.status.toString()} - ${queue.progress?.completedLength} / ${queue.progress?.totalLength}'));
        }),
      )),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
  }
}
