import 'package:comic_nyaa/data/download/nyaa_download_task_queue.dart';
import 'package:comic_nyaa/widget/simple_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'marquee_widget.dart';

class DownloadItem extends StatelessWidget {
  const DownloadItem(this.item, {Key? key}) : super(key: key);
  final NyaaDownloadTaskQueue item;

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 128,
        margin: const EdgeInsets.all(4),
        child: Material(
            elevation: 2,
            child: InkWell(
                onTap: () {},
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  SimpleNetworkImage(
                    item.cover,
                    headers: item.headers,
                    width: 96,
                    fit: BoxFit.cover,
                    // height: 128,
                  ),
                  Expanded(
                    child: Container(
                        margin: const EdgeInsets.all(8),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                  child:
                                      MarqueeWidget(child: Text(item.title))),
                              Row(children: [
                                Material(
                                  color: Theme.of(context).primaryColor,
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
                                  child: Text(
                                      '${item.progress?.completedLength} / ${item.progress?.totalLength}'),
                                )),
                                Text(
                                  DateFormat('yyyy/M/d hh:mm')
                                      .format(item.createDate.toLocal()),
                                  maxLines: 1,
                                )
                              ])
                            ])),
                  )
                ]))));
  }
}
