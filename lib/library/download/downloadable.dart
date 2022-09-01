import 'dart:collection';

enum DownloadStatus { idle, loading, failed, successful }

class DownloadProgress {
  DownloadProgress(this.totalByteLength, {this.completesByteLength = 0});

  int completesByteLength;
  int totalByteLength;

  double get progress {
    return totalByteLength > 0 ? completesByteLength / totalByteLength : -1.0;
  }
}

abstract class Downloadable<T> {
  Downloadable(this.url, this.path);

  DownloadStatus status = DownloadStatus.idle;
  DownloadProgress? pregress;
  String url;
  String path;

  Future<T> start();

  Future<T> stop();
}
