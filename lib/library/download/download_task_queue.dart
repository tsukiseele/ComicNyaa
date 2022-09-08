import 'package:comic_nyaa/library/download/downloadable.dart';

import 'downloadable_queue.dart';

class DownloadTaskQueue<T extends Downloadable> extends DownloadableQueue<T> {
  DownloadTaskQueue(super.createDate);

  List<T> finishTasks = [];
  List<T> tasks = [];

  bool isSingle() {
    return tasks.length == 1;
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
    tasks = [];
    finishTasks = [];
    queue.clear();
  }

  @override
  Future<void> onDownloading() async {
    status = DownloadStatus.loading;
    tasks = queue.toList();
    while (queue.isNotEmpty) {
      if (status == DownloadStatus.pause) return;
      final task = removeFirst();
      try {
        await task.start();
      } catch (e) {
        print('FAILED ChlidTask::: ${task.url}');
        // task.status =
      } finally {
        finishTasks.add(task);
        progress = DownloadProgress(finishTasks.length, tasks.length);
        onProgress(progress!);
      }
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
  Future<void> onProgress(DownloadProgress progress) async {}
}
