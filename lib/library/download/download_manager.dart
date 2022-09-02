
import 'package:comic_nyaa/library/download/task_runner.dart';

import 'downloadable_queue.dart';

class DownloadManager {
  DownloadManager._();
  static DownloadManager? _instance;
  static DownloadManager get instance => _instance ??= DownloadManager._();

  Map<String, DownloadableQueue> tasks = {};
  TaskRunner taskRunner = TaskRunner<DownloadableQueue, void>((task) async {
    try {
      await task.start();
    } catch (e) {
      rethrow;
    } finally {}
  });

  void add(DownloadableQueue downloadable) {
    taskRunner.add(downloadable);
  }

  void addAll(Iterable<DownloadableQueue> downloadables) {
    taskRunner.addAll(downloadables);
  }
}
