import 'package:comic_nyaa/library/download/download_task.dart';
import 'package:comic_nyaa/library/download/download_task_queue.dart';
import 'package:comic_nyaa/library/download/downloadable.dart';
import 'package:comic_nyaa/models/typed_model.dart';
import 'package:comic_nyaa/utils/extensions.dart';

import '../../app/preference.dart';
import '../../library/mio/core/mio.dart';

class NyaaDownloadTaskQueue extends DownloadTaskQueue {
  late String directory;
  late int level;
  late TypedModel parent;
  late String title;
  late String cover;
  int? id;

  NyaaDownloadTaskQueue.fromJson(Map<String, dynamic> data) {
    directory = data['directory'];
    level = int.parse(data['level']);
    cover = data['cover'];
    title = data['title'];
    parent = TypedModel.fromJson(data['parent']);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = {};
    data['directory'] = directory;
    data['level'] = level;
    data['cover'] = cover;
    data['title'] = title;
    data['parent'] = parent.toJson().toString();
    return data;
  }

  Future<NyaaDownloadTaskQueue> initialize() async {
    status = DownloadStatus.init;
    try {
      final drl = DownloadResourceLevel.fromDbCode(level);
      final origin = parent.getOrigin();
      headers = origin.site.headers;

      parent = TypedModel.fromJson(
          await Mio(origin.site).parseAllChildren(parent.toJson()));
      if (title.isEmpty) title = parent.title ?? '';
      if (parent.children?.isEmpty == true) {
        queue.add(DownloadTask.fromUrl(directory, parent.getUrl(drl)));
      } else {
        for (var child in parent.children!) {
          queue.add(DownloadTask.fromUrl(directory, child.getUrl(drl)));
        }
      }
    } catch (e) {
      status = DownloadStatus.failed;
      error = e;
    }
    return this;
  }
  @override
  Future<void> start() async {
    // print('');
    super.start();
  }

  NyaaDownloadTaskQueue(
      {required this.parent,
      required this.directory,
      this.level = 2,
      this.title = '',
      this.cover = ''}) {
    cover = parent.coverUrl ?? '';
  }
}
