import 'package:comic_nyaa/library/download/download_task_queue.dart';
import 'package:comic_nyaa/utils/extensions.dart';
import 'package:comic_nyaa/utils/uri_extensions.dart';

import '../../app/global.dart';
import '../../app/preference.dart';
import '../../library/download/download_task.dart';
import '../../library/mio/core/mio.dart';
import '../../models/typed_model.dart';

class NyaaDownloadManager {
  Future<void> addAll(Iterable<TypedModel> items) async {
    DownloadTaskQueue queue = DownloadTaskQueue(items);
    final results = await Future.wait(items.map((item) => Mio(item.$site).parseAllChildren(item.toJson(), item.$section!.rules!)));
    final downloadDir = await Config.downloadDir;
    final downloadLevel = (await NyaaPreferences.instance).downloadResourceLevel;
    addAll(results.map((json) {
      final item = TypedModel.fromJson(json);
      final url = item.getUrl(downloadLevel);
      final path = downloadDir.join(Uri.parse(url).filename).path;
      return DownloadTask(url, path);
    }));
  }
}