import 'dart:convert';
import 'dart:io';
import 'package:comic_nyaa/library/download/download_task_queue.dart';
import 'package:comic_nyaa/library/download/downloadable.dart';
import 'package:comic_nyaa/models/typed_model.dart';
import 'package:comic_nyaa/utils/extensions.dart';

import '../../app/preference.dart';
import '../../library/mio/core/mio.dart';
import 'nyaa_download_manager.dart';
import 'nyaa_download_task.dart';

class NyaaDownloadTaskQueue extends DownloadTaskQueue<NyaaDownloadTask> {
  int? id;
  late String directory;
  late DownloadResourceLevel level;
  late TypedModel parent;
  late String title;
  late String cover;
  List<NyaaDownloadTask> tasks = [];

  NyaaDownloadTaskQueue.fromJson(Map<String, dynamic> data): super(DateTime.parse(data['createDate'])) {
    directory = data['directory'];
    cover = data['cover'];
    title = data['title'];
    path = data['path'];
    url = data['url'];
    level = DownloadResourceLevel.fromDbValue(data['level']);
    status = DownloadStatus.fromDbValue(data['status']);
    parent = TypedModel.fromJson(jsonDecode(data['parent']));
    progress = DownloadProgress(data['completedLength'], data['totalLength']);
    final tList = jsonDecode(data['tasks']);
    tasks = tList is List ? tList.map((item) => NyaaDownloadTask.fromJson(item)).toList() : [];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = {};
    data['directory'] = directory;
    data['cover'] = cover;
    data['title'] = title;
    data['path'] = path;
    data['url'] = url;
    data['level'] = level.value;
    data['status'] = status.value;
    data['parent'] = jsonEncode(parent.toJson());
    data['createDate'] = createDate.toIso8601String();
    data['completedLength'] = progress?.completedLength ?? 0;
    data['totalLength'] = progress?.totalLength ?? 0;
    data['tasks'] = jsonEncode(tasks);
    return data;
  }

  /// 获取下载列表，添加到队列
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
        queue.add(NyaaDownloadTask.fromUrl(directory, parent.getUrl(level)));
      } else if (children.length == 1) {
        queue.add(NyaaDownloadTask.fromUrl(directory, children[0].getUrl(level)));
      } else {
        directory = Directory(directory).join(title + cover.hashCode.toString()).path;
        for (var child in parent.children!) {
          queue.add(NyaaDownloadTask.fromUrl(directory, child.getUrl(level)));
        }
      }
      tasks.addAll(queue);
    } catch (e) {
      status = DownloadStatus.failed;
      error = e;
      rethrow;
    } finally {
      (await NyaaDownloadManager.instance).downloadProvider.update(this);
    }
    return this;
  }

  @override
  Future<void> onDownloading() async {
    await super.onDownloading();
    print('NyaaDownloadTaskQueue::: status ==> $status');
    (await NyaaDownloadManager.instance).downloadProvider.update(this);
  }

  @override
  Future<void> onDone() async {
    await super.onDone();
    print('NyaaDownloadTaskQueue::: status ==> $status');

    (await NyaaDownloadManager.instance).downloadProvider.update(this);
  }

  NyaaDownloadTaskQueue({required this.parent, required this.directory, required DateTime createDate, this.level = DownloadResourceLevel.medium}) : super(createDate) {
    cover = parent.coverUrl ?? '';
    title = parent.title ?? '';
  }
}
