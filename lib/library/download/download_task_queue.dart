import 'package:comic_nyaa/library/download/downloadable.dart';

import 'downloadable_queue.dart';

class DownloadTaskQueue<T extends Downloadable> extends DownloadableQueue<T> {
  DownloadTaskQueue(super.createDate);

  List<T> tasks = [];

  void add(T downloadable) {
    tasks.add(downloadable);
  }

  void addAll(Iterable<T> iterable) {
    tasks.addAll(iterable);
  }

  @override
  Future<void> start() async {
    await onInitialize();
    await onDownloading();
    await onDone();
  }

  @override
  Future<void> pause() async {
    await onPause();
  }

  @override
  Future<void> resume() async {
    await start();
  }

  @override
  Future<void> onInitialize() async {
    status = DownloadStatus.init;
  }

  @override
  Future<void> onDownloading() async {
    status = DownloadStatus.loading;
    if (tasks.isNotEmpty) {
      queue.clear();
      queue.addAll(tasks);
    }
    int finishCount = 0;
    onProgress(DownloadProgress(finishCount, tasks.length));
    while (queue.isNotEmpty) {
      if (status == DownloadStatus.pause) return;
      final task = queue.removeFirst();
      try {
        await task.start();
        finishCount++;
      } catch (e) {
        print('FAILED! DownloadTask::: ${task.url}');
        // task.status =
      } finally {
        onProgress(DownloadProgress(finishCount, tasks.length));
      }
    }
    onProgress(DownloadProgress(finishCount, tasks.length));
    status = DownloadStatus.successful;
  }

  @override
  Future<void> onDone() async {
    // status = DownloadStatus.successful;
  }

  @override
  Future<void> onPause() async {
    status = DownloadStatus.pause;
  }

  @override
  Future<void> onProgress(DownloadProgress progress) async {
    this.progress = progress;
  }

  bool isSingle() {
    return tasks.length == 1;
  }
}
