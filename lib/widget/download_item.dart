import 'package:comic_nyaa/data/download/nyaa_download_task.dart';
import 'package:comic_nyaa/library/download/download_task.dart';
import 'package:comic_nyaa/widget/simple_network_image.dart';
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
        height: 128,
        margin: const EdgeInsets.all(4),
        child: Material(
            // elevation: 2,
            child: InkWell(
                onTap: () {},
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Material(
                    elevation: 2,
                    borderOnForeground: true,
                    child: SimpleNetworkImage(
                      item.cover ?? '',
                      headers: item.headers,
                      width: 96,
                      fit: BoxFit.cover,
                      height: double.maxFinite,
                    ),
                  ),
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
                              ])
                            ])),
                  )
                ]))));
  }
}
