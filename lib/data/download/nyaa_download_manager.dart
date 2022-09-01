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

  Future<void> addAll(Iterable<TypedModel> items) async {
    final List<DownloadTaskQueue> tasks = [];
    final results = await Future.wait(items.map((item) => Mio(item.$site).parseAllChildren(item.toJson(), item.$section!.rules!)));
    final downloadDir = await Config.downloadDir;
    final downloadLevel = (await NyaaPreferences.instance).downloadResourceLevel;
    tasks.addAll(results.map((json) {
      DownloadTaskQueue queue = DownloadTaskQueue();
      final item = TypedModel.fromJson(json);
      if (item.children?.isEmpty == true) {
        final url = item.getUrl(downloadLevel);
        final path = downloadDir.join(Uri.parse(url).filename).path;
        queue.add(DownloadTask(url, path));
      } else {
        for (var child in item.children!){
          final url = child.getUrl(downloadLevel);
          final path = downloadDir.join(Uri.parse(url).filename).path;
          queue.add(DownloadTask(url, path));
        }
      }
      return queue;
    }));
    for (var task in tasks) {
      DownloadManager.instance.add(task);
    }
  }
}