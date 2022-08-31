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

class DownloadTaskQueue extends DownloadableQueue<DownloadTask> {
  DownloadTaskQueue(super.queue);

  @override
  void start() {
    // TODO: implement start
  }

  @override
  void stop() {
    // TODO: implement stop
  }
}