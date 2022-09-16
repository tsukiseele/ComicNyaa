
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

import 'package:comic_nyaa/library/download/task_runner.dart';

import 'downloadable_queue.dart';

class DownloadManager {
  DownloadManager._();
  static DownloadManager? _instance;
  static DownloadManager get instance => _instance ??= DownloadManager._();

  TaskRunner taskRunner = TaskRunner<DownloadableQueue, void>((task) async {
    try {
      await task.start();
    } catch (e) {
      rethrow;
    } finally {}
  });

  void add(DownloadableQueue downloadable) {
    taskRunner.add(downloadable);
  }

  void addAll(Iterable<DownloadableQueue> downloadables) {
    taskRunner.addAll(downloadables);
  }
}
