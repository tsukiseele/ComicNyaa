
import 'package:flutter/cupertino.dart';

enum DownloadStatus {
  idle('IDLE'),
  init('INIT'),
  loading('LOADING'),
  pause('PAUSE'),
  failed('FAILED'),
  successful('SUCCESSFUL');

  const DownloadStatus(this.value);
  final String value;

  static DownloadStatus fromDbValue(String value) => DownloadStatus.values.firstWhere((item) => item.value == value);
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
  Downloadable(this.url, this.path, this.createDate);

  DownloadStatus status = DownloadStatus.idle;
  DownloadProgress? progress;
  DateTime createDate;
  Object? error;
  String url;
  String path;
  Map<String, String>? headers;

  Future<T> start();

  Future<T> pause();

  Future<T> resume();

  @mustCallSuper
  Future<T> onInitialize();

  @mustCallSuper
  Future<T> onDownloading();

  @mustCallSuper
  Future<T> onProgress(DownloadProgress progress);

  @mustCallSuper
  Future<T> onPause();

  @mustCallSuper
  Future<T> onDone();

  @mustCallSuper
  Future<T> onFailed(Object? error);

  bool get isFailed => status == DownloadStatus.failed;

  bool get isSuccessful => status == DownloadStatus.successful;
}
