import 'package:comic_nyaa/data/download/nyaa_download_task_queue.dart';
import 'package:comic_nyaa/library/download/download_manager.dart';
import 'package:comic_nyaa/library/download/download_task_queue.dart';
import 'package:comic_nyaa/utils/extensions.dart';
import 'package:comic_nyaa/utils/uri_extensions.dart';

import '../../app/global.dart';
import '../../app/preference.dart';
import '../../library/download/download_task.dart';
import '../../library/mio/core/mio.dart';
import '../../models/typed_model.dart';

enum NyaaDownloadStatus {
  // 初始状态
  idle,
  // 等待解析
  wait,
  // 下载中
  loading,
  // 暂停
  pause,
  // 失败
  failed,
  // 完成
  successful
}

class NyaaDownloadManager {
  NyaaDownloadManager._();
  static NyaaDownloadManager? _instance;
  static NyaaDownloadManager get instance => _instance ??= NyaaDownloadManager._();

  final List<NyaaDownloadTaskQueue> _tasks = [];

  List<NyaaDownloadTaskQueue> get tasks => _tasks;

  Future<void> addAll(Iterable<TypedModel> items) async {
    final List<NyaaDownloadTaskQueue> tasks = [];
    final results = await Future.wait(items.map((item) => Mio(item.$site).parseAllChildren(item.toJson(), item.$section!.rules!)));
    final downloadDir = await Config.downloadDir;
    final downloadLevel = (await NyaaPreferences.instance).downloadResourceLevel;
    tasks.addAll(results.map((json) {
      final item = TypedModel.fromJson(json);
      NyaaDownloadTaskQueue queue = NyaaDownloadTaskQueue(item.title ?? '');
      if (item.children?.isEmpty == true) {
        queue.add(DownloadTask.fromUrl(downloadDir, item.getUrl(downloadLevel)));
      } else {
        for (var child in item.children!) {
          queue.add(DownloadTask.fromUrl(downloadDir, child.getUrl(downloadLevel)));
        }
      }
      return queue;
    }));
    _tasks.addAll(tasks);
    for (var task in tasks) {
      DownloadManager.instance.add(task);
    }
  }
}