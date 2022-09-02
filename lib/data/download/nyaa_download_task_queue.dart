import 'dart:io';

import 'package:comic_nyaa/library/download/download_task.dart';
import 'package:comic_nyaa/library/download/download_task_queue.dart';
import 'package:comic_nyaa/library/download/downloadable.dart';
import 'package:comic_nyaa/models/typed_model.dart';
import 'package:comic_nyaa/utils/extensions.dart';

import '../../app/preference.dart';
import '../../library/mio/core/mio.dart';

class NyaaDownloadTaskQueue extends DownloadTaskQueue {
  TypedModel parent;
  final Directory directory;
  final DownloadResourceLevel level;
  String name;
  String cover;


  Future<NyaaDownloadTaskQueue> initialize() async {
    status = DownloadStatus.init;
    try {
      parent = TypedModel.fromJson(await Mio(parent.$site)
          .parseAllChildren(parent.toJson(), parent.$section!.rules!));
      if (name.isEmpty) name = parent.title ?? '';
      if (parent.children?.isEmpty == true) {
        queue.add(DownloadTask.fromUrl(directory, parent.getUrl(level)));
      } else {
        for (var child in parent.children!) {
          queue.add(DownloadTask.fromUrl(directory, child.getUrl(level)));
        }
      }
    } catch (e) {
      status = DownloadStatus.failed;
      error = e;
    }
    return this;
  }

  NyaaDownloadTaskQueue({
    required this.parent,
    required this.directory,
    this.name = '',
    this.level = DownloadResourceLevel.medium,
  });
}
