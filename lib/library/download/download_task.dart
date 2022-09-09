import 'dart:io';
import '../http/http.dart';
import '../http/nyaa_client.dart';
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
      // 存在则跳过，直接返回
      if (await target.exists()) {
        print('File is exists, skip it::: $target ');
        final length = await target.length();
        progress = DownloadProgress(length, length);
        status = DownloadStatus.successful;
        return;
      }
      // 创建父级目录
      if (!await target.parent.exists()) {
        await target.parent.create();
      }
      // 开始下载并监听回调
      await Http.downloadFileBreakPointer(url, path, headers: headers, onProgress: (received, total) {
        status = DownloadStatus.loading;
        progress = DownloadProgress(received, total);
        onProgress(progress!);
      });
    } catch (e) {
      status = DownloadStatus.failed;
      print(e);
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
