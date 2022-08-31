import 'package:comic_nyaa/utils/download/downloadable.dart';

class DownloadTask extends Downloadable {
  DownloadTask(String url, String path) : super(url, path);

  @override
  Future<void> start() async {
  }

  @override
  Future<void> stop() async {
    // TODO: implement stop
  }
}
