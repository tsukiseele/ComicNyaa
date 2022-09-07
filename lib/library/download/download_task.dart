import 'dart:io';

import 'package:comic_nyaa/utils/extensions.dart';
import 'package:comic_nyaa/utils/h_client.dart';
import 'package:comic_nyaa/utils/uri_extensions.dart';
import 'downloadable.dart';

class DownloadTask extends Downloadable<void> {
  DownloadTask(super.url, super.path, super.createDate);

  @override
  Future<void> start() async {
    await onInitialize();
    await onDownloading();
    await onDone();
  }

  @override
  Future<void> onInitialize() async {
    status = DownloadStatus.init;
  }

  @override
  Future<void> onDownloading() async {
    print('DownloadTask::: downloading >>> url: $url, path: $path');
    try {
      final target = File(path);
      if (!await target.parent.exists()) {
        await target.parent.create();
      }
      await HClient.download(url, path, (received, total) {
        status = DownloadStatus.loading;
        progress = DownloadProgress(received, total);
        print('PROGRESS::: $progress');
        onProgress(progress!);
      });
    } catch (e) {
      status = DownloadStatus.failed;
      rethrow;
    }
  }

  @override
  Future<void> onDone() async {
    status = DownloadStatus.successful;
  }

  @override
  Future<void> onPause() async {
    status = DownloadStatus.pause;
  }

  factory DownloadTask.fromUrl(String downloadDir, String url) {
    final path = Directory(downloadDir).join(Uri.parse(url).filename).path;
    return DownloadTask(url, path, DateTime.now());
  }

  @override
  Future<void> pause() {
    // TODO: implement pause
    throw UnimplementedError();
  }

  @override
  Future<void> resume() {
    // TODO: implement resume
    throw UnimplementedError();
  }

  @override
  Future<void> onProgress(DownloadProgress progress) async {}
}
