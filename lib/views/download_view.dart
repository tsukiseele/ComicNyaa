import 'dart:async';

import 'package:comic_nyaa/data/download/nyaa_download_manager.dart';
import 'package:comic_nyaa/widget/simple_network_image.dart';
import 'package:flutter/material.dart';

import '../data/download/nyaa_download_task_queue.dart';

class DownloadView extends StatefulWidget {
  const DownloadView(
      {Key? key, this.updateInterval = const Duration(milliseconds: 1000)})
      : super(key: key);
  final Duration updateInterval;

  @override
  State<StatefulWidget> createState() {
    return _DownloadViewState();
  }
}

class _DownloadViewState extends State<DownloadView> {
  List<NyaaDownloadTaskQueue> _downloadList = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    loopUpdateStatus();
  }

  void loopUpdateStatus() {
    _update();
    _timer = Timer.periodic(widget.updateInterval, (timer) => _update());
  }

  Future<void> _update() async {
    final tasks = (await NyaaDownloadManager.instance).tasks;
    print('TTTTTTTTTTTTTTTTTTT::: ${tasks.length}');
    setState(() => _downloadList = tasks);
  }

  @override
  Widget build(BuildContext context) {

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
                  '${queue.status.value} - ${queue.progress?.completedLength} / ${queue.progress?.totalLength}'));
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
