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

import 'package:comic_nyaa/library/download/downloadable.dart';

import 'downloadable_queue.dart';

class DownloadTaskQueue<T extends Downloadable> extends DownloadableQueue<T> {
  DownloadTaskQueue(super.createDate);

  List<T> tasks = [];

  void add(T downloadable) {
    tasks.add(downloadable);
  }

  void addAll(Iterable<T> iterable) {
    tasks.addAll(iterable);
  }

  @override
  Future<void> start() async {
    await onInitialize();
    await onDownloading();
    await onDone();
  }

  @override
  Future<void> pause() async {
    await onPause();
  }

  @override
  Future<void> resume() async {
    await start();
  }

  @override
  Future<void> onInitialize() async {
    status = DownloadStatus.init;
  }

  @override
  Future<void> onDownloading() async {
    status = DownloadStatus.progress;
    if (tasks.isNotEmpty) {
      queue.clear();
      queue.addAll(tasks);
    }
    int finishCount = 0;
    onProgress(DownloadProgress(finishCount, tasks.length));
    while (queue.isNotEmpty) {
      if (status == DownloadStatus.pause) return;
      final task = queue.removeFirst();
      try {
        await task.start();
        finishCount++;
      } catch (e) {
        onFailed(e);
        // rethrow;
      } finally {
        onProgress(DownloadProgress(finishCount, tasks.length));
      }
    }
    onProgress(DownloadProgress(finishCount, tasks.length));
    status = DownloadStatus.successful;
  }

  @override
  Future<void> onDone() async {
  }

  @override
  Future<void> onPause() async {
    status = DownloadStatus.pause;
  }

  @override
  Future<void> onProgress(DownloadProgress progress) async {
    this.progress = progress;
  }

  bool isSingle() {
    return tasks.length == 1;
  }

  @override
  Future<void> onFailed(Object? error) async {
    status = DownloadStatus.failed;
    this.error = error;
    print('[DownloadTaskQueue]: FAILED:: $error');
  }
}
