import 'dart:io';

import 'package:comic_nyaa/utils/extensions.dart';
import 'package:comic_nyaa/utils/http.dart';
import 'package:comic_nyaa/utils/uri_extensions.dart';
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

  factory DownloadTask.fromUrl(String downloadDir, String url) {
    final path = Directory(downloadDir).join(Uri.parse(url).filename).path;
    return DownloadTask(url, path);
  }

  @override
  Future<void> pause() async {
    status = DownloadStatus.pause;
  }
}
