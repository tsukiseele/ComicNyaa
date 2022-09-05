import 'dart:io';

import 'package:comic_nyaa/library/download/download_task.dart';
import 'package:comic_nyaa/library/download/download_task_queue.dart';
import 'package:comic_nyaa/library/download/downloadable.dart';
import 'package:comic_nyaa/models/typed_model.dart';
import 'package:comic_nyaa/utils/extensions.dart';

import '../../app/preference.dart';
import '../../library/mio/core/mio.dart';

class NyaaDownloadTaskQueue extends DownloadTaskQueue {
  late int id;
  late String directory;
  late int level;
  late TypedModel parent;
  late String name;
  late String cover;

  NyaaDownloadTaskQueue.fromJson(Map<String, dynamic> data) {
    id = data['id'];
    directory = data['directory'];
    level = int.parse(data['level']);
    cover = data['cover'];
    name = data['name'];
    parent = data['parent'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = {};
    data['id'] = id;
    data['directory'] = directory;
    data['level'] = level;
    data['cover'] = cover;
    data['name'] = name;
    data['parent'] = parent;
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
      if (name.isEmpty) name = parent.title ?? '';
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

  NyaaDownloadTaskQueue(
      {required this.parent,
      required this.directory,
      this.level = 2,
      this.name = '',
      this.cover = ''}) {
    cover = parent.coverUrl ?? '';
  }
}
