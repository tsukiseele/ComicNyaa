import 'dart:io';

import 'package:comic_nyaa/data/download/nyaa_download_manager.dart';
import 'package:comic_nyaa/data/download_provider.dart';
import 'package:comic_nyaa/library/download/download_manager.dart';
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
    cover = data['cover'];
    title = data['title'];
    path = data['path'];
    url = data['url'];
    status = DownloadStatus.fromDbValue(data['status']);
    level = int.parse(data['level']);
    parent = TypedModel.fromJson(data['parent']);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = {};
    data['directory'] = directory;
    data['level'] = level;
    data['cover'] = cover;
    data['title'] = title;
    data['path'] = path;
    data['url'] = url;
    data['status'] = status.toDbValue();
    data['parent'] = parent.toJson().toString();
    return data;
  }

  @override
  Future<NyaaDownloadTaskQueue> onInitialize() async {
    status = DownloadStatus.init;
    try {
      (await NyaaDownloadManager.instance.downloadProvider).insert(this);
      final drl = DownloadResourceLevel.fromDbCode(level);
      final origin = parent.getOrigin();
      headers = origin.site.headers;

      parent = TypedModel.fromJson(
          await Mio(origin.site).parseAllChildren(parent.toJson()));
      if (title.isEmpty) title = parent.title ?? '';
      if (parent.children == null || parent.children!.length <= 1) {
        queue.add(DownloadTask.fromUrl(directory, parent.getUrl(drl)));
      } else {
        directory = Directory(directory).join(title + cover.hashCode.toString()).path;
        for (var child in parent.children!) {
          queue.add(DownloadTask.fromUrl(directory, child.getUrl(drl)));
        }
      }
    } catch (e) {
      status = DownloadStatus.failed;
      error = e;
    } finally {
      (await NyaaDownloadManager.instance.downloadProvider).update(this);
    }
    return this;
  }

  @override
  Future<void> onDone() async {
    (await NyaaDownloadManager.instance.downloadProvider).update(this);
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
