import 'dart:io';

import 'package:comic_nyaa/app/global.dart';
import 'package:comic_nyaa/utils/http.dart';
import 'package:comic_nyaa/utils/uri_extensions.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'downloadable.dart';

class DownloadTask extends Downloadable {
  DownloadTask(String url, String path) : super(url, path);

  @override
  Future<void> start() async {
    status = DownloadStatus.idle;
    try {
      await Http.client().download(url, path,
          onReceiveProgress: (received, total) {
        status = DownloadStatus.loading;
        progress = DownloadProgress(received, total);
      });
    } catch (e) {
      status = DownloadStatus.failed;
    }
    status = DownloadStatus.successful;
  }

  @override
  Future<void> stop() async {}

  factory DownloadTask.fromUrl(Directory downloadDir, String url) {
    final path = downloadDir.join(Uri.parse(url).filename).path;
    return DownloadTask(url, path);
  }
}
