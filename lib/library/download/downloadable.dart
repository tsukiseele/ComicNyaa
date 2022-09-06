
enum DownloadStatus {
  idle('IDLE'),
  init('INIT'),
  loading('LOADING'),
  pause('PAUSE'),
  failed('FAILED'),
  successful('SUCCESSFUL');

  static DownloadStatus fromDbValue(String value) {
    switch (value) {
      case 'IDLE':
        return DownloadStatus.idle;
      case 'INIT':
        return DownloadStatus.init;
      case 'LOADING':
        return DownloadStatus.loading;
      case 'PAUSE':
        return DownloadStatus.pause;
      case 'FAILED':
        return DownloadStatus.failed;
      case 'SUCCESSFUL':
        return DownloadStatus.successful;
      default:
        return DownloadStatus.idle;
    }
  }
  String toDbValue() {
    switch (this) {
      case DownloadStatus.idle:
        return'IDLE';
      case DownloadStatus.init:
        return 'INIT';
      case DownloadStatus.loading:
        return 'LOADING';
      case DownloadStatus.pause:
        return 'PAUSE';
      case DownloadStatus.failed:
        return 'FAILED';
      case DownloadStatus.successful:
        return 'SUCCESSFUL';
    }
  }
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

  Future<T> pause();

  Future<T> resume();

  Future<T> onInitialize();

  Future<T> onDownloading();

  Future<T> onProgress(DownloadProgress progress);

  Future<T> onPause();

  Future<T> onDone();

  bool get isFailed => status == DownloadStatus.failed;

  bool get isSuccessful => status == DownloadStatus.successful;
}
