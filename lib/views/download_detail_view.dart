/*
 * Copyright (C) 2022. TsukiSeele
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

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
            padding: const EdgeInsets.all(8),
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
