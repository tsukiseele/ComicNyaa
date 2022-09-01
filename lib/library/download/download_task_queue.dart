import 'download_task.dart';
import 'downloadable_queue.dart';

class DownloadTaskQueue extends DownloadableQueue<DownloadTask> {
  DownloadTaskQueue();

  @override
  Future<void> start() async {
    while (queue.isNotEmpty) {
      final task = queue.removeFirst();
      await task.start();
    }
  }

  @override
  Future<void> stop() async {}
}
