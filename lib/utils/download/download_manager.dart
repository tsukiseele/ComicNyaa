import 'package:comic_nyaa/utils/download/downloadable.dart';
import 'package:comic_nyaa/utils/download/task_runner.dart';

class DownloadManager {
  DownloadManager._();
  static DownloadManager? _instance;
  static DownloadManager get instance => _instance ??= DownloadManager._();

  Map<String, Downloadable> tasks = {};
  TaskRunner taskRunner = TaskRunner<DownloadableQueue, void>((task) async {
    try {
      await task.start();
    } catch (e) {
      rethrow;
    } finally {}
  });

  void add(Downloadable downloadable) {
    taskRunner.add(downloadable);
  }
}
