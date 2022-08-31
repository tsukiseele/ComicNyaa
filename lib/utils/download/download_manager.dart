import 'package:comic_nyaa/utils/download/downloadable.dart';
import 'package:comic_nyaa/utils/download/task_runner.dart';

class DownloadManager {
  Map<String, Downloadable> tasks = {};
  TaskRunner taskRunner = TaskRunner<Downloadable, Downloadable>((task) {

  })
  void add(Downloadable downloadable) {

  }

}