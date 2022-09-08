import 'dart:math';

import 'package:comic_nyaa/data/download/nyaa_download_task.dart';
import 'package:comic_nyaa/widget/simple_network_image.dart';
import 'package:comic_nyaa/widget/triangle_painter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../library/download/downloadable.dart';
import '../utils/num_extensions.dart';
import 'download_group_item.dart';
import 'marquee_widget.dart';

class DownloadItem extends StatelessWidget {
  const DownloadItem(this.item, {Key? key}) : super(key: key);
  final NyaaDownloadTask item;

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 120,
        margin: const EdgeInsets.only(top: 4, bottom: 4, left: 8, right: 8),
        child: Material(
            elevation: 1,
            // borderRadius: BorderRadius.circular(4),
            clipBehavior: Clip.hardEdge,
            child: InkWell(
                onTap: () {},
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      clipBehavior: Clip.hardEdge,
                      decoration: const BoxDecoration(
                          border:
                              Border(right: BorderSide(color: Colors.black12))),
                      child: Stack(children: [
                        SimpleNetworkImage(
                          item.cover ?? '',
                          headers: item.headers,
                          width: 80,
                          fit: BoxFit.cover,
                          height: double.maxFinite,
                        ),
                        // Positioned(
                        //     top: 0,
                        //     right: 0,
                        //     child: triangle(
                        //         width: 64,
                        //         height: 64,
                        //         color: Theme.of(context).primaryColor,
                        //         direction: TriangleDirection.topRight,
                        //         // contentPadding: EdgeInsets.only(),
                        //         child: const Icon(
                        //           Icons.dashboard,
                        //           color: Colors.white,
                        //           size: 18,
                        //         )))
                      ])),
                  Expanded(
                    child: Container(
                        margin: const EdgeInsets.all(8),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                  child: MarqueeWidget(
                                      child: Text(
                                item.url,
                                maxLines: 2,
                              ))),
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                alignment: AlignmentDirectional.centerEnd,
                                child: Text(
                                  DateFormat('yyyy/M/d hh:mm')
                                      .format(item.createDate.toLocal()),
                                  maxLines: 1,
                                ),
                              ),
                              item.status != DownloadStatus.successful
                                  ? Padding(
                                      padding: const EdgeInsets.only(
                                          top: 8, bottom: 8),
                                      child: item.progress != null
                                          ? LinearProgressIndicator(
                                              value: item.progress!
                                                      .completedLength /
                                                  item.progress!.totalLength)
                                          : const LinearProgressIndicator())
                                  : Container(),
                              Row(children: [
                                Material(
                                  color: getColorByStatus(item.status),
                                  elevation: 2,
                                  child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Text(
                                        item.status.value,
                                        maxLines: 1,
                                        style: const TextStyle(
                                            color: Colors.white),
                                      )),
                                ),
                                Expanded(
                                    child: Padding(
                                  padding:
                                      const EdgeInsets.only(left: 4, right: 4),
                                  child: Text(item.progress != null &&
                                          item.status !=
                                              DownloadStatus.successful
                                      ? getProgressText(
                                          item.progress!.completedLength,
                                          item.progress!.totalLength)
                                      : ''),
                                )),
                              ])
                            ])),
                  )
                ]))));
  }
}
