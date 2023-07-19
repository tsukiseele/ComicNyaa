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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:comic_nyaa/data/download/nyaa_download_manager.dart';
import 'package:comic_nyaa/data/download/nyaa_download_task_queue.dart';
import 'package:comic_nyaa/widget/custom_dialog.dart';
import 'package:comic_nyaa/widget/download_group_item.dart';
import 'package:comic_nyaa/widget/download_item.dart';
import 'package:comic_nyaa/views/download_detail_view.dart';
import 'package:comic_nyaa/utils/flutter_utils.dart';

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
  final StateNotifier notifier = StateNotifier();

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
    setState(() => _downloadList = tasks);
    notifier.notify();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('下载')),
      body: Material(
        child: ListView(
          padding: const EdgeInsets.all(8),
            children: List.generate(_downloadList.length, (index) {
          final item = _downloadList[index];
          return item.isSingle()
              ? DownloadItem(
                  item.tasks.first,
                  origin: item.parent.getOrigin(),
                  onLongPress: () => _onItemLongPress(item),
                )
              : DownloadQueueItem(
                  item,
                  onTap: () => onShowDetail(item),
                  onLongPress: () => _onItemLongPress(item),
                );
        })),
      ),
    );
  }

  void onShowDetail(NyaaDownloadTaskQueue item) {
    RouteUtil.push(context, DownloadDetailView(item, notifier: notifier));
  }

  void _onItemLongPress(NyaaDownloadTaskQueue item) {
    OptionsDialog(context,
        title: item.title,
        optionsBuilder: (context, dialog) => [
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('删除'),
                onTap: () {
                  _onDeleteItem(item);
                  dialog.dismiss();
                },
              )
            ]).show();
  }

  void _onDeleteItem(NyaaDownloadTaskQueue item) async {
    (await NyaaDownloadManager.instance).delete(item);
    _update();
    Fluttertoast.showToast(msg: '${item.title} 已删除！');
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
  }
}

class StateNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}
