/*
 * Copyright (C) 2022. TsukiSeele
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:convert';
import 'dart:io';
import 'package:comic_nyaa/library/download/download_task_queue.dart';
import 'package:comic_nyaa/library/download/downloadable.dart';
import 'package:comic_nyaa/models/typed_model.dart';
import 'package:comic_nyaa/utils/extensions.dart';
import 'package:comic_nyaa/utils/string_extensions.dart';

import '../../app/app_preference.dart';
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

  NyaaDownloadTaskQueue.fromJson(Map<String, dynamic> data)
      : super(DateTime.parse(data['createDate'])) {
    id = data['id'];
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
    tasks = tList is List
        ? tList.map((item) => NyaaDownloadTask.fromJson(item)).toList()
        : [];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = {};
    data['id'] = id;
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

  /// ????????????????????????????????????
  @override
  Future<void> onInitialize() async {
    await super.onInitialize();
    try {
      // ???????????????????????????????????????????????????????????????????????????????????????
      if (tasks.isNotEmpty) return;
      // ?????????id????????????????????????????????????????????????
      if (id == null) {
        (await NyaaDownloadManager.instance).downloadProvider.insert(this);
      }
      // ???????????????????????????????????????
      final origin = parent.getOrigin();
      headers = origin.site.headers;

      Map<String, dynamic> parentJson = parent.toJson();
      // ??????????????????
      parentJson = await Mio(origin.site).parseExtended(item: parentJson);
      // ????????????
      parent = TypedModel.fromJson(
          await Mio(origin.site).parseAllChildren(parentJson));
      title = parent.title ?? '';
      final children = parent.children;
      if (children == null || children.isEmpty) {
        add(NyaaDownloadTask.fromUrl(directory, parent.getUrl(level),
            title: parent.title, cover: parent.coverUrl, headers: headers));
      } else if (children.length == 1) {
        add(NyaaDownloadTask.fromUrl(directory, children.first.getUrl(level),
            title: StringUtil.value(children.first.title, parent.title),
            cover: StringUtil.value(children.first.coverUrl, parent.coverUrl),
            headers: headers));
      } else {
        // ????????????????????????????????????????????????????????????????????????????????????????????????????????????
        directory = Directory(directory)
            .join(title /*'${title}_${cover.hashCode}'*/);
        for (var child in parent.children!) {
          add(NyaaDownloadTask.fromUrl(directory, child.getUrl(level),
              title: child.title, cover: child.coverUrl, headers: headers));
        }
      }
    } catch (e) {
      onFailed(e);
      rethrow;
    } finally {
      // ?????????????????????????????????????????????
      (await NyaaDownloadManager.instance).downloadProvider.update(this);
    }
    return;
  }

  @override
  Future<void> onDownloading() async {
    print('NyaaDownloadTaskQueue::: status ==> $status');
    await super.onDownloading();
  }

  @override
  Future<void> onDone() async {
    await super.onDone();
    print('NyaaDownloadTaskQueue::: status ==> $status');
    print(
        'STATE: ${status.value}: ${progress?.totalLength} / ${progress?.completedLength}');
    (await NyaaDownloadManager.instance).downloadProvider.update(this);
  }

  NyaaDownloadTaskQueue(
      {required this.parent,
      required this.directory,
      required DateTime createDate,
      this.level = DownloadResourceLevel.medium})
      : super(createDate) {
    cover = parent.coverUrl ?? '';
    title = parent.title ?? '';
  }
}
