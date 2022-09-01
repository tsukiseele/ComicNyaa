import 'package:comic_nyaa/library/download/downloadable.dart';

import 'download_task.dart';
import 'downloadable_queue.dart';

class DownloadTaskQueue extends DownloadableQueue<DownloadTask> {
  List<DownloadTask> finishTasks = [];

  @override
  Future<void> start() async {
    status = DownloadStatus.loading;
    while (queue.isNotEmpty) {
      final task = queue.removeFirst();
      await task.start();
      finishTasks.add(task);
      progress = DownloadProgress(finishTasks.length, queue.length);
    }
    status = DownloadStatus.successful;
  }

  @override
  Future<void> stop() async {}
}
