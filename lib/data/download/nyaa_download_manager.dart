import 'package:comic_nyaa/data/download/nyaa_download_task_queue.dart';
import 'package:comic_nyaa/data/download_provider.dart';
import 'package:comic_nyaa/library/download/download_manager.dart';
import 'package:sqflite/sqflite.dart';

import '../../app/config.dart';
import '../../app/preference.dart';
import '../../models/typed_model.dart';

class NyaaDownloadManager {
  static NyaaDownloadManager? _instance;

  static Future<NyaaDownloadManager> get instance async {
    return _instance ??= NyaaDownloadManager._(await DownloadProvider().open(await getDatabasesPath()));
  }
  NyaaDownloadManager._(this.downloadProvider) {
    restoreTasks();
  }

  final DownloadProvider downloadProvider;

  final List<NyaaDownloadTaskQueue> _tasks = [];

  List<NyaaDownloadTaskQueue> get tasks => _tasks;

  restoreTasks() async {
    tasks.addAll(await downloadProvider.getTasks());
  }

  Future<void> addAll(Iterable<TypedModel> items) async {
    final downloadDir = await Config.downloadDir;
    final downloadLevel =
        (await NyaaPreferences.instance).downloadResourceLevel;
    // final tasks = await Future.wait(items.map((item) => NyaaDownloadTaskQueue(
    //         parent: item,
    //         directory: downloadDir.path,
    //         level: downloadLevel.toDbCode())
    //     .onInitialize()));

    final tasks = items.map((item) => NyaaDownloadTaskQueue(
              parent: item,
              directory: downloadDir.path,
              level: downloadLevel));

    // for (var element in tasks) {
    //   (await downloadProvider).insert(element);
    // }
    DownloadManager.instance.addAll(tasks);
    _tasks.addAll(tasks);
  }
}
