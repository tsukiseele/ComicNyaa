import 'package:comic_nyaa/data/download/nyaa_download_task_queue.dart';
import 'package:flutter/material.dart';

import '../widget/download_item.dart';

class DownloadDetailView extends StatefulWidget {
  const DownloadDetailView(this.queue, {Key? key, this.notifier})
      : super(key: key);
  final NyaaDownloadTaskQueue queue;
  final ChangeNotifier? notifier;

  @override
  State<StatefulWidget> createState() => _DownloadDetailViewState();
}

class _DownloadDetailViewState extends State<DownloadDetailView> {
  void _update() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.notifier?.addListener(_update);
  }

  @override
  Widget build(BuildContext context) {
    final tasks = widget.queue.tasks.toList();
    return Scaffold(
      appBar: AppBar(title: Text(widget.queue.title)),
      body: Material(
          child: ListView(
        children:
            List.generate(tasks.length, (index) => DownloadItem(tasks[index], origin: widget.queue.parent.getOrigin())),
      )),
    );
  }

  @override
  void dispose() {
    super.dispose();
    widget.notifier?.removeListener(_update);
  }
}
