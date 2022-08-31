
import 'dart:collection';

enum DownloadStatus { idle, loading, failed, successful }

class DownloadProgress {
  DownloadProgress(this.totalByteLength, { this.completesByteLength = 0 });

  int completesByteLength;
  int totalByteLength;

  double get progress {
    return totalByteLength > 0 ? completesByteLength / totalByteLength : -1.0;
  }
}

abstract class Downloadable<T> {
  Downloadable();

  DownloadStatus status = DownloadStatus.idle;
  DownloadProgress? pregress;

  void start();

  void stop();
}

abstract class DownloadableQueue<T extends Downloadable> extends Downloadable {
  DownloadableQueue(this._queue);

  final Queue<T> _queue;

  int length() {
    return _queue.length;
  }

  void add(T downloadable) {
    _queue.add(downloadable);
  }

  bool remove(T downloadable) {
    return _queue.remove(downloadable);
  }

  T removeFirst() {
    return _queue.removeFirst();
  }

  T removeLast() {
    return _queue.removeLast();
  }
}