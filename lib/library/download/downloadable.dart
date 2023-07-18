
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

import 'package:flutter/cupertino.dart';

enum DownloadStatus {
  idle('IDLE'),
  init('INIT'),
  progress('PROGRESS'),
  pause('PAUSE'),
  failed('FAILED'),
  successful('SUCCESSFUL');

  const DownloadStatus(this.value);
  final String value;

  static DownloadStatus fromDbValue(String value) => DownloadStatus.values.firstWhere((item) => item.value == value);
}

class DownloadProgress {
  DownloadProgress(this.completedLength, this.totalLength);

  int completedLength;
  int totalLength;

  double get progress {
    return totalLength > 0 ? completedLength / totalLength : -1.0;
  }
}

abstract class Downloadable<T> {
  Downloadable(this.url, this.path, this.createDate);

  DownloadStatus status = DownloadStatus.idle;
  DownloadProgress? progress;
  DateTime createDate;
  Object? error;
  String url;
  String path;
  Map<String, String>? headers;

  Future<T> start();

  Future<T> pause();

  Future<T> resume();

  @mustCallSuper
  Future<T> onInitialize();

  @mustCallSuper
  Future<T> onDownloading();

  @mustCallSuper
  Future<T> onProgress(DownloadProgress progress);

  @mustCallSuper
  Future<T> onPause();

  @mustCallSuper
  Future<T> onDone();

  @mustCallSuper
  Future<T> onFailed(Object? error);

  bool get isFailed => status == DownloadStatus.failed;

  bool get isSuccessful => status == DownloadStatus.successful;
}
