import 'dart:io';

import 'package:comic_nyaa/utils/extensions.dart';
import 'package:comic_nyaa/utils/http.dart';
import 'package:comic_nyaa/utils/uri_extensions.dart';
import 'downloadable.dart';

class DownloadTask extends Downloadable<void> {
  DownloadTask(String url, String path) : super(url, path);

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
    try {
      await Http.client().download(url, path,
          onReceiveProgress: (received, total) {
            status = DownloadStatus.loading;
            progress = DownloadProgress(received, total);
            onProgress(progress!);
          });
    } catch (e) {
      status = DownloadStatus.failed;
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
    return DownloadTask(url, path);
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
  Future<void> onProgress(DownloadProgress progress) async {
  }
}
