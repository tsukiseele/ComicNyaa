import 'package:comic_nyaa/data/download/nyaa_download_task_queue.dart';
import 'package:flutter/material.dart';

import '../widget/download_item.dart';

class DownloadDetailView extends StatefulWidget {
  const DownloadDetailView(this.queue, {Key? key}) : super(key: key);
final NyaaDownloadTaskQueue queue;
  @override
  State<StatefulWidget> createState() => _DownloadDetailViewState();

}

class _DownloadDetailViewState extends State<DownloadDetailView> {
  @override
  Widget build(BuildContext context) {
    final queue = widget.queue.queue.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('下载')),
      body: Material(
          child: ListView(
            children: List.generate(widget.queue.queue.length,
                    (index) => DownloadItem(queue[index])),
          )),
    );
  }

}