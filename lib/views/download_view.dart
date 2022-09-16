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

import 'package:comic_nyaa/data/download/nyaa_download_manager.dart';
import 'package:comic_nyaa/utils/flutter_utils.dart';
import 'package:flutter/material.dart';

import '../data/download/nyaa_download_task_queue.dart';
import '../widget/download_group_item.dart';
import '../widget/download_item.dart';
import 'download_detail_view.dart';

class DownloadView extends StatefulWidget {
  const DownloadView({Key? key, this.updateInterval = const Duration(milliseconds: 1000)}) : super(key: key);
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
    // WidgetsBinding.instance.addPostFrameCallback((timeStamp) => ));
  }

  Future<void> _update() async {
    final tasks = (await NyaaDownloadManager.instance).tasks;
    setState(() => _downloadList = tasks);
    notifier.notify();
  }

  void onShowDetail(NyaaDownloadTaskQueue item) {
    RouteUtil.push(context, DownloadDetailView(item, notifier: notifier));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('下载')),
      body: Material(
          child: Container(
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        child: ListView(
            children: List.generate(_downloadList.length, (index) {
          final item = _downloadList[index];
          // print('SSSSSSSSSSSSSSSS::: IS_SINGLE => ${item.isSingle()}, ${item.tasks}');
          return item.isSingle() ? DownloadItem(item.tasks.first, origin: item.parent.getOrigin()) : DownloadQueueItem(item, onTap: () => onShowDetail(item));
        })),
      )),
    );
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
