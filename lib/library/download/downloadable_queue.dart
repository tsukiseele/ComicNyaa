
import 'dart:collection';

import 'downloadable.dart';

abstract class DownloadableQueue<T> extends Downloadable {
  DownloadableQueue(DateTime createDate) : super('', '', createDate);
  final Queue<T> _queue = Queue();

  Queue<T> get queue => _queue;

  int get length => queue.length;

  void add(T downloadable) {
    queue.add(downloadable);
  }

  void addAll(Iterable<T> iterable) {
    queue.addAll(iterable);
  }

  bool remove(T downloadable) {
    return queue.remove(downloadable);
  }

  T removeFirst() {
    return queue.removeFirst();
  }

  T removeLast() {
    return queue.removeLast();
  }

  isSingle() {
    return queue.length == 1;
  }

  T get first => queue.first;
}
