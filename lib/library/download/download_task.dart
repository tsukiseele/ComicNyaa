import 'dart:io';
import 'package:comic_nyaa/utils/h_client.dart';
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
    status = DownloadStatus.loading;
    try {
      final target = File(path);
      if (await target.exists()) {
        final length = await target.length();
        progress = DownloadProgress(length, length);
        status = DownloadStatus.successful;
      }
      if (!await target.parent.exists()) {
        await target.parent.create();
      }
      await HClient.download(url, path, headers: headers, onProgress: (received, total) {
        status = DownloadStatus.loading;
        progress = DownloadProgress(received, total);
        onProgress(progress!);
      });
    } catch (e) {
      status = DownloadStatus.failed;
      // rethrow;
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
