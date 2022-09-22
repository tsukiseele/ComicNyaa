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

import 'package:comic_nyaa/utils/extensions.dart';
import 'package:comic_nyaa/utils/uri_extensions.dart';

import '../../library/download/download_task.dart';
import '../../library/download/downloadable.dart';

class NyaaDownloadTask extends DownloadTask {
  String? cover;
  String? title;

  NyaaDownloadTask(super.url, super.path, super.createDate, {this.title, this.cover, Map<String, String>? headers}) {
    this.headers = headers;
  }

  NyaaDownloadTask.fromJson(Map<String, dynamic> data) : super(data['url'], data['path'], DateTime.parse(data['createDate'])) {
    status = DownloadStatus.fromDbValue(data['status']);
    progress = DownloadProgress(data['completedLength'], data['totalLength']);
    cover = data['cover'];
    title = data['title'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = {};
    data['path'] = path;
    data['url'] = url;
    data['title'] = title;
    data['cover'] = cover;
    data['status'] = status.value;
    data['createDate'] = createDate.toIso8601String();
    data['completedLength'] = progress?.completedLength ?? 0;
    data['totalLength'] = progress?.totalLength ?? 0;
    return data;
  }

  factory NyaaDownloadTask.fromUrl(String downloadDir, String url, {String? title, String? cover, Map<String, String>? headers}) {
    final path = Directory(downloadDir).join(Uri.parse(url).filename);
    return NyaaDownloadTask(url, path, DateTime.now(), title: title, cover: cover, headers: headers);
  }
}
