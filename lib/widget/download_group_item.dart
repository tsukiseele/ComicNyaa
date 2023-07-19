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

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:comic_nyaa/widget/simple_network_image.dart';
import 'package:comic_nyaa/widget/triangle_painter.dart';
import 'package:comic_nyaa/data/download/nyaa_download_task_queue.dart';
import 'package:comic_nyaa/library/download/downloadable.dart';

const Color idle = Colors.grey;
const Color downloading = Colors.blue;
const Color successful = Colors.teal;
const Color failed = Colors.red;

Color getColorByStatus(DownloadStatus status) {
  switch (status) {
    case DownloadStatus.idle:
    case DownloadStatus.pause:
      return idle;
    case DownloadStatus.init:
    case DownloadStatus.progress:
      return downloading;
    case DownloadStatus.successful:
      return successful;
    case DownloadStatus.failed:
      return failed;
    default:
      return idle;
  }
}

IconData getIconDataByNumber(int number) {
  switch (number) {
    case 0:
      return Icons.filter;
    case 1:
      return Icons.looks_one_outlined;
    case 2:
      return Icons.filter_2;
    case 3:
      return Icons.filter_3;
    case 4:
      return Icons.filter_4;
    case 5:
      return Icons.filter_5;
    case 6:
      return Icons.filter_6;
    case 7:
      return Icons.filter_7;
    case 8:
      return Icons.filter_8;
    case 9:
      return Icons.filter_9;
    default:
      return Icons.filter_9_plus;
  }
}

class DownloadQueueItem extends StatelessWidget {
  const DownloadQueueItem(this.item, {Key? key, this.onTap, this.onLongPress})
      : super(key: key);
  final NyaaDownloadTaskQueue item;
  final void Function()? onTap;
  final void Function()? onLongPress;

  Widget _buildProgressText(DownloadProgress? progress) {
    if (progress == null) {
      return const Text('');
    }
    return Text('${progress.completedLength} / ${progress.totalLength} pics');
  }

  Widget _buildProgressIndicator(DownloadProgress? progress) {
    if (item.status == DownloadStatus.init) {
      return const LinearProgressIndicator();
    }
    if (item.status == DownloadStatus.progress) {
      if (item.progress != null && item.progress!.totalLength > 0) {
        return LinearProgressIndicator(
            value: item.progress!.completedLength / item.progress!.totalLength);
      } else {
        return const LinearProgressIndicator();
      }
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    final origin = item.parent.getOrigin();
    return Container(
        height: 108,
        margin: const EdgeInsets.only(bottom: 8),
        child: Material(
            elevation: 0.5,
            color: const Color.fromARGB(255, 224, 240, 240),
            borderRadius: BorderRadius.circular(4),
            clipBehavior: Clip.hardEdge,
            child: InkWell(onTap: onTap, onLongPress: onLongPress, child:
              Row(mainAxisSize: MainAxisSize.min, children: [
                Material(
                    color: Colors.grey[100],
                    child: Stack(children: [
                      SimpleNetworkImage(
                        item.cover,
                        headers: item.headers,
                        width: 80,
                        fit: BoxFit.cover,
                        height: double.maxFinite,
                      ),
                      Positioned(
                          top: 0,
                          left: 0,
                          child: triangle(
                              width: 40,
                              height: 40,
                              color: Theme.of(context).primaryColor,
                              direction: TriangleDirection.topLeft,
                              contentPadding: const EdgeInsets.all(2),
                              child: Icon(
                                getIconDataByNumber(item.tasks.length),
                                color: Colors.white,
                                size: 18,
                              )))
                    ])),
                Expanded(
                  child: Container(
                      margin: const EdgeInsets.only(top: 4, right: 8, bottom: 4, left: 8),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                                child: Text(
                              item.title,
                              maxLines: 2,
                              style: const TextStyle(fontSize: 16),
                            )),
                            Container(
                                // margin: const EdgeInsets.only(bottom: ),
                                alignment: AlignmentDirectional.centerEnd,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      origin.site.name ?? '',
                                      maxLines: 1,
                                      style: TextStyle(
                                          color: Colors.teal[200],
                                          fontSize: 16),
                                    ),
                                    const Spacer(),
                                    Text(
                                      DateFormat('yyyy/M/d hh:mm')
                                          .format(item.createDate.toLocal()),
                                      maxLines: 1,
                                    )
                                  ],
                                )),
                            _buildProgressIndicator(item.progress),
                            Row(children: [
                              Material(
                                color: getColorByStatus(item.status),
                                elevation: 2,
                                child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Text(
                                      item.status.value,
                                      maxLines: 1,
                                      style:
                                          const TextStyle(color: Colors.white),
                                    )),
                              ),
                              Expanded(
                                  child: Padding(
                                padding:
                                    const EdgeInsets.only(left: 4, right: 4),
                                child: _buildProgressText(item.progress),
                              )),
                              item.status == DownloadStatus.progress
                                  ? InkWell(
                                      onTap: () => onPause(item),
                                      child: const Padding(
                                          padding: EdgeInsets.all(4),
                                          child: Icon(Icons.pause)))
                                  : InkWell(
                                      onTap: () => onRestart(item),
                                      child: const Padding(
                                          padding: EdgeInsets.all(4),
                                          child: Icon(Icons.play_arrow)))
                            ])
                          ])),
                )
              ])
            )));
  }

  Future<void> onRestart(NyaaDownloadTaskQueue tasks) async {
    await tasks.start();
    final successfulCount = tasks.tasks
        .where((item) => item.status == DownloadStatus.successful)
        .length;
    Fluttertoast.showToast(
        msg:
            '任务已完成: ${tasks.title}， 成功: $successfulCount 项，失败: ${tasks.tasks.length - successfulCount} 项');
    // (await NyaaDownloadManager.instance).restart(tasks.parent);
  }

  Future<void> onPause(NyaaDownloadTaskQueue tasks) async {
    await tasks.pause();
    // (await NyaaDownloadManager.instance).restart(tasks.parent);
  }
}
