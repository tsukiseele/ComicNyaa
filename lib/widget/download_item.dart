import 'dart:math';

import 'package:comic_nyaa/data/download/nyaa_download_task.dart';
import 'package:comic_nyaa/library/mio/model/data_origin.dart';
import 'package:comic_nyaa/models/typed_model.dart';
import 'package:comic_nyaa/widget/nyaa_tag_item.dart';
import 'package:comic_nyaa/widget/simple_network_image.dart';
import 'package:comic_nyaa/widget/triangle_painter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../library/download/downloadable.dart';
import '../utils/num_extensions.dart';
import 'download_group_item.dart';
import 'marquee_widget.dart';

class DownloadItem extends StatelessWidget {
  const DownloadItem(this.item, {Key? key, this.origin}) : super(key: key);
  final NyaaDownloadTask item;
  final DataOrigin? origin;

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
        return Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: LinearProgressIndicator(value: item.progress!.completedLength / item.progress!.totalLength));
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
            child: InkWell(
                onTap: () {
                  print('IIIIIIIIIIIIIII::: ${item.cover}');
                },
                child: Row(mainAxisSize: MainAxisSize.min, children: [
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
                ]))));
  }
  Future<void> onRestart(NyaaDownloadTask task) async {
    task.start();
    // (await NyaaDownloadManager.instance).restart(tasks.parent);
  }


  Future<void> onPause(NyaaDownloadTask task) async {
    task.pause();
    // (await NyaaDownloadManager.instance).restart(tasks.parent);
  }
}
