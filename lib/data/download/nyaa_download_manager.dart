import 'package:comic_nyaa/data/download/nyaa_download_task_queue.dart';
import 'package:comic_nyaa/library/download/download_manager.dart';

import '../../app/global.dart';
import '../../app/preference.dart';
import '../../models/typed_model.dart';

class NyaaDownloadManager {
  NyaaDownloadManager._();

  static NyaaDownloadManager? _instance;

  static NyaaDownloadManager get instance =>
      _instance ??= NyaaDownloadManager._();

  final List<NyaaDownloadTaskQueue> _tasks = [];

  List<NyaaDownloadTaskQueue> get tasks => _tasks;

  Future<void> addAll(Iterable<TypedModel> items) async {
    final downloadDir = await Config.downloadDir;
    final downloadLevel =
        (await NyaaPreferences.instance).downloadResourceLevel;
    final tasks = await Future.wait(items.map((item) => NyaaDownloadTaskQueue(
            parent: item, directory: downloadDir, level: downloadLevel)
        .initialize()));
    DownloadManager.instance.addAll(tasks);
    _tasks.addAll(tasks);
  }
}
