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

import 'package:comic_nyaa/library/mio/model/data_origin.dart';
import 'package:comic_nyaa/library/download/downloadable.dart';
import 'package:comic_nyaa/widget/simple_network_image.dart';
import 'package:comic_nyaa/widget/download_group_item.dart';
import 'package:comic_nyaa/widget/ink_stack.dart';
import 'package:comic_nyaa/data/download/nyaa_download_task.dart';
import 'package:comic_nyaa/utils/num_extensions.dart';

class DownloadItem extends StatelessWidget {
  const DownloadItem(this.item, {Key? key, this.origin, this.onTap, this.onLongPress}) : super(key: key);
  final NyaaDownloadTask item;
  final DataOrigin? origin;
  final void Function()? onTap;
  final void Function()? onLongPress;

  Widget _buildProgressText(DownloadProgress? progress) {
    if (progress == null) {
      return const Text('');
    }
    if (item.status == DownloadStatus.successful || progress.totalLength <= 0) {
      return Text(progress.completedLength.readableFileSize());
    }
    return Text('${progress.completedLength.readableFileSize()} / ${progress.totalLength.readableFileSize()}');
  }

  Widget _buildProgressIndicator(DownloadProgress? progress) {
    if (item.status == DownloadStatus.init) {
      return const LinearProgressIndicator();
    }
    if (item.status == DownloadStatus.loading) {
      if (item.progress != null && item.progress!.totalLength > 0) {
        return LinearProgressIndicator(value: item.progress!.completedLength / item.progress!.totalLength);
      } else {
        return const LinearProgressIndicator();
      }
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 112,
        margin: const EdgeInsets.only(top: 2, bottom: 2, left: 8, right: 8),
        child: Material(
            elevation: 1,
            borderRadius: BorderRadius.circular(2),
            clipBehavior: Clip.hardEdge,
            child: InkStack(
                onTap: onTap,
                onLongPress: onLongPress,
                children: [Row(mainAxisSize: MainAxisSize.min, children: [
                  Material(
                    color: Colors.grey[100],
                    child: SimpleNetworkImage(
                      item.cover ?? '',
                      headers: item.headers,
                      width: 80,
                      fit: BoxFit.contain,
                      height: double.maxFinite,
                    ),
                  ),
                  Expanded(
                    child: Container(
                        margin: const EdgeInsets.all(8),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Expanded(
                              child: Text(
                            item.title ?? '',
                            maxLines: 2,
                            style: const TextStyle(fontSize: 16),
                          )),
                          Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              alignment: AlignmentDirectional.centerEnd,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    origin?.site.name ?? '',
                                    maxLines: 1,
                                    style: TextStyle(color: Colors.teal[200], fontSize: 16),
                                  ),
                                  const Spacer(),
                                  Text(
                                    DateFormat('yyyy/M/d hh:mm').format(item.createDate.toLocal()),
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
                                    style: const TextStyle(color: Colors.white),
                                  )),
                            ),
                            Expanded(
                                child: Padding(
                              padding: const EdgeInsets.only(left: 4, right: 4),
                              child: _buildProgressText(item.progress),
                            )),
                            item.status == DownloadStatus.loading
                                ? InkWell(
                                onTap: () => onPause(item),
                                child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.pause)))
                                : InkWell(
                                onTap: () => onRestart(item),
                                child: const Padding(padding: EdgeInsets.all(4), child:  Icon(Icons.play_arrow)))
                          ])
                        ])),
                  )
                ])])));
  }
  Future<void> onRestart(NyaaDownloadTask task) async {
    await task.start();
    Fluttertoast.showToast(msg: '??????????????????${task.title}');
    // (await NyaaDownloadManager.instance).restart(tasks.parent);
  }

  Future<void> onPause(NyaaDownloadTask task) async {
    task.pause();
    // (await NyaaDownloadManager.instance).restart(tasks.parent);
  }
}
