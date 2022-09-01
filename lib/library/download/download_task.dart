import 'package:comic_nyaa/utils/http.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'downloadable.dart';

class DownloadTask extends Downloadable {
  DownloadTask(String url, String path) : super(url, path);

  @override
  Future<void> start() async {
    status = DownloadStatus.idle;
    try {
      await Http.client().download(url, path,
          onReceiveProgress: (received, total) {
        status = DownloadStatus.loading;
        pregress = DownloadProgress(total, completesByteLength: received);
      });
    } catch (e) {
      status = DownloadStatus.failed;
    }
    status = DownloadStatus.successful;
  }

  @override
  Future<void> stop() async {

  }
}
