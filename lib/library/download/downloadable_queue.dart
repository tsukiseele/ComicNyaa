
import 'dart:collection';

import 'package:flutter/material.dart';

import 'downloadable.dart';

abstract class DownloadableQueue<T> extends Downloadable {
  DownloadableQueue(DateTime createDate) : super('', '', createDate);
  final Queue<T> _queue = Queue();

  Queue<T> get queue => _queue;

  // T get first => queue.first;

  // @mustCallSuper
  // void add(T downloadable) {
  //   queue.add(downloadable);
  // }
  //
  // @mustCallSuper
  // void addAll(Iterable<T> iterable) {
  //   queue.addAll(iterable);
  // }
  //
  // @mustCallSuper
  // bool remove(T downloadable) {
  //   return queue.remove(downloadable);
  // }
  //
  // @mustCallSuper
  // T removeFirst() {
  //   return queue.removeFirst();
  // }
  //
  // @mustCallSuper
  // T removeLast() {
  //   return queue.removeLast();
  // }
}
