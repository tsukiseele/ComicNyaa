import 'package:comic_nyaa/utils/download/downloadable.dart';

class DownloadTask extends Downloadable {
  DownloadTask(this.url): super(false);

  String url;

  @override
  void start() {
  }

  @override
  void stop() {
    // TODO: implement stop
  }
}

class DownloadTaskGroup extends Downloadable {

}