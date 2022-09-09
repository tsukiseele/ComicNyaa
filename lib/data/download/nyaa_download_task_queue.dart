import 'dart:convert';
import 'dart:io';
import 'package:comic_nyaa/library/download/download_task_queue.dart';
import 'package:comic_nyaa/library/download/downloadable.dart';
import 'package:comic_nyaa/models/typed_model.dart';
import 'package:comic_nyaa/utils/extensions.dart';
import 'package:comic_nyaa/utils/string_extensions.dart';

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

  NyaaDownloadTaskQueue.fromJson(Map<String, dynamic> data) : super(DateTime.parse(data['createDate'])) {
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
  Future<void> onInitialize() async {
    await super.onInitialize();
    try {
      // 存在任务列表，代表已经初始化完成，直接跳过初始化，执行下载
      if (tasks.isNotEmpty) return;
      // 不存在id，表示任务组不存在，插入到数据库
      if (id == null) (await NyaaDownloadManager.instance).downloadProvider.insert(this);
      // 执行初始化逻辑，生成任务组
      final origin = parent.getOrigin();
      headers = origin.site.headers;
      parent = TypedModel.fromJson(await Mio(origin.site).parseAllChildren(parent.toJson()));
      if (title.isEmpty) title = parent.title ?? '';
      final children = parent.children;
      if (children == null || children.isEmpty) {
        add(NyaaDownloadTask.fromUrl(directory, parent.getUrl(level), title: parent.title, cover: parent.coverUrl));
      } else if (children.length == 1) {
        add(NyaaDownloadTask.fromUrl(directory, children[0].getUrl(level),
            title: StringUtil.value(children[0].title, parent.title),
            cover: StringUtil.value(children[0].coverUrl, parent.coverUrl)));
      } else {
        // 一旦使用散列码，虽然能避免任务名重复，但是将失去缓存检测，这里不使用散列
        directory = Directory(directory).join(title /*'${title}_${cover.hashCode}'*/).path;
        for (var child in parent.children!) {
          add(NyaaDownloadTask.fromUrl(directory, child.getUrl(level),
              title: child.title, cover: child.coverUrl));
        }
      }
    } catch (e) {
      status = DownloadStatus.failed;
      error = e;
    } finally {
      // (await NyaaDownloadManager.instance).downloadProvider.update(this);
    }
    return;
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

  NyaaDownloadTaskQueue(
      {required this.parent, required this.directory, required DateTime createDate, this.level = DownloadResourceLevel.medium})
      : super(createDate) {
    cover = parent.coverUrl ?? '';
    title = parent.title ?? '';
  }
}
