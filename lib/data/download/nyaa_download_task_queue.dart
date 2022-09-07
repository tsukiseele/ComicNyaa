import 'dart:convert';
import 'dart:io';

import 'package:comic_nyaa/data/download/nyaa_download_manager.dart';
import 'package:comic_nyaa/library/download/download_task.dart';
import 'package:comic_nyaa/library/download/download_task_queue.dart';
import 'package:comic_nyaa/library/download/downloadable.dart';
import 'package:comic_nyaa/models/typed_model.dart';
import 'package:comic_nyaa/utils/extensions.dart';

import '../../app/preference.dart';
import '../../library/mio/core/mio.dart';

class NyaaDownloadTaskQueue extends DownloadTaskQueue {
  late String directory;
  late DownloadResourceLevel level;
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
    level = DownloadResourceLevel.fromDbCode(data['level']);
    status = DownloadStatus.fromDbValue(data['status']);
    parent = TypedModel.fromJson(jsonDecode(data['parent']));
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = {};
    data['directory'] = directory;
    data['cover'] = cover;
    data['title'] = title;
    data['path'] = path;
    data['url'] = url;
    data['level'] = level.toDbCode();
    data['status'] = status.toDbValue();
    data['parent'] = jsonEncode(parent.toJson());
    return data;
  }

  @override
  Future<NyaaDownloadTaskQueue> onInitialize() async {
    await super.onInitialize();
    try {
      (await NyaaDownloadManager.instance).downloadProvider.insert(this);
      final origin = parent.getOrigin();
      headers = origin.site.headers;
      parent = TypedModel.fromJson(await Mio(origin.site).parseAllChildren(parent.toJson()));
      if (title.isEmpty) title = parent.title ?? '';
      final children = parent.children;
      if (children == null || children.isEmpty) {
        queue.add(DownloadTask.fromUrl(directory, parent.getUrl(level)));
      } else if (children.length == 1) {
        queue.add(DownloadTask.fromUrl(directory, children[0].getUrl(level)));
      } else {
        directory = Directory(directory).join(title + cover.hashCode.toString()).path;
        for (var child in parent.children!) {
          queue.add(DownloadTask.fromUrl(directory, child.getUrl(level)));
        }
      }
    } catch (e) {
      status = DownloadStatus.failed;
      error = e;
    } finally {
      (await NyaaDownloadManager.instance).downloadProvider.update(this);
    }
    return this;
  }

  @override
  Future<void> onDownloading() async {
    await super.onDownloading();
    print('DOWNLOADDDDDDDDDDDDDDDDDDDDDDDDD：：： $status');
    (await NyaaDownloadManager.instance).downloadProvider.update(this);
  }

  @override
  Future<void> onDone() async {
    await super.onDone();
    print('DONEEEEEEEEEEEEEEEEEEEEEEEEEEEEE');

    (await NyaaDownloadManager.instance).downloadProvider.update(this);
  }

  NyaaDownloadTaskQueue({required this.parent, required this.directory, this.level = DownloadResourceLevel.medium}) {
    cover = parent.coverUrl ?? '';
    title = parent.title ?? '';
  }
}
