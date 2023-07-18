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

import 'dart:io';
import '../http/http.dart';
import 'downloadable.dart';

class DownloadTask extends Downloadable<void> {
  DownloadTask(super.url, super.path, super.createDate);

  @override
  Future<void> start() async {
    await onInitialize();
    await onDownloading();
    await onDone();
  }

  @override
  Future<void> onInitialize() async {
    status = DownloadStatus.init;
  }

  @override
  Future<void> onDownloading() async {
    print('DownloadTask::: downloading >>> url: $url, path: $path');
    status = DownloadStatus.progress;
    try {
      final target = File(path);
      // 存在则跳过，直接返回
      if (await target.exists()) {
        print('File is exists, skip it::: $target ');
        final length = await target.length();
        progress = DownloadProgress(length, length);
        status = DownloadStatus.successful;
        return;
      }
      // 创建父级目录
      if (!await target.parent.exists()) {
        await target.parent.create();
      }
      // 开始下载并监听回调
      await Http.downloadFileBreakPointer(url, path, headers: headers, onProgress: (received, total) {
        status = DownloadStatus.progress;
        progress = DownloadProgress(received, total);
        onProgress(progress!);
      });
    } catch (e) {
      onFailed(e);
      rethrow;
    }
  }

  @override
  Future<void> onDone() async {
    status = DownloadStatus.successful;
  }

  @override
  Future<void> onPause() async {
    status = DownloadStatus.pause;
  }

  @override
  Future<void> pause() {
    // TODO: implement pause
    throw UnimplementedError();
  }

  @override
  Future<void> resume() {
    // TODO: implement resume
    throw UnimplementedError();
  }

  @override
  Future<void> onProgress(DownloadProgress progress) async {}

  @override
  Future<void> onFailed(Object? error) async {
    status = DownloadStatus.failed;
    this.error = error;
    print('[DownloadTask]: FAILED:: $error');
  }
}
