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

import 'package:comic_nyaa/data/download/nyaa_download_task_queue.dart';
import 'package:comic_nyaa/data/download/download_provider.dart';
import 'package:comic_nyaa/library/download/download_manager.dart';

import '../../app/app_config.dart';
import '../../app/app_preference.dart';
import '../../models/typed_model.dart';

class NyaaDownloadManager {
  static NyaaDownloadManager? _instance;

  static Future<NyaaDownloadManager> get instance async {
    return _instance ??= NyaaDownloadManager._(
        await DownloadProvider().open());
  }

  NyaaDownloadManager._(this.downloadProvider) {
    restoreTasks();
  }

  final DownloadProvider downloadProvider;

  final List<NyaaDownloadTaskQueue> _tasks = [];

  List<NyaaDownloadTaskQueue> get tasks => _tasks;

  restoreTasks() async {
    _tasks.addAll(await downloadProvider.getTasks());
  }

  Future<void> add(TypedModel item) async {
    final downloadDir = await AppConfig.downloadDir;
    final downloadLevel =
        (await AppPreferences.instance).downloadResourceLevel;
    final task = NyaaDownloadTaskQueue(
        parent: item,
        directory: downloadDir.path,
        level: downloadLevel,
        createDate: DateTime.now());
    DownloadManager.instance.add(task);
    _tasks.insert(0, task);
  }

  Future<void> addAll(Iterable<TypedModel> items) async {
    final downloadDir = await AppConfig.downloadDir;
    final downloadLevel =
        (await AppPreferences.instance).downloadResourceLevel;
    final tasks = items.map((item) => NyaaDownloadTaskQueue(
        parent: item,
        directory: downloadDir.path,
        level: downloadLevel,
        createDate: DateTime.now())).toList();
    DownloadManager.instance.addAll(tasks);
    _tasks.insertAll(0, tasks);
  }

  Future<void> delete(NyaaDownloadTaskQueue item) async {
    item.pause();
    (await NyaaDownloadManager.instance)
        .downloadProvider
        .delete(item);
    tasks.remove(item);
  }
  restart(NyaaDownloadTaskQueue queue) {
    DownloadManager.instance.add(queue);
  }
}
