
enum DownloadStatus {
  idle('IDLE'),
  init('INIT'),
  loading('LOADING'),
  pause('PAUSE'),
  failed('FAILED'),
  successful('SUCCESSFUL');

  const DownloadStatus(this.value);
  final String value;
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
  Downloadable(this.url, this.path);

  DownloadStatus status = DownloadStatus.idle;
  DownloadProgress? progress;
  Object? error;
  String url;
  String path;
  Map<String, String>? headers;

  Future<T> start();

  Future<T> stop();

  Future<T> pause();

  bool isFailed() {
    return status == DownloadStatus.failed;
  }
}
