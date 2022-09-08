import 'dart:io';

import 'package:comic_nyaa/utils/extensions.dart';
import 'package:comic_nyaa/utils/uri_extensions.dart';

import '../../library/download/download_task.dart';
import '../../library/download/downloadable.dart';

class NyaaDownloadTask extends DownloadTask {
  String? cover;
  NyaaDownloadTask(super.url, super.path, super.createDate, {this.cover});

  NyaaDownloadTask.fromJson(Map<String, dynamic> data): super(data['url'], data['path'], DateTime.parse(data['createDate'])) {
    status = DownloadStatus.fromDbValue(data['status']);
    progress = DownloadProgress(data['completedLength'], data['totalLength']);
    cover = data['cover'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = {};
    data['path'] = path;
    data['url'] = url;
    data['status'] = status.value;
    data['createDate'] = createDate.toIso8601String();
    data['completedLength'] = progress?.completedLength ?? 0;
    data['totalLength'] = progress?.totalLength ?? 0;
    return data;
  }

  factory NyaaDownloadTask.fromUrl(String downloadDir, String url, {String? cover}) {
    final path = Directory(downloadDir).join(Uri.parse(url).filename).path;
    return NyaaDownloadTask(url, path, DateTime.now(), cover: cover);
  }
}