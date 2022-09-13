
import 'dart:collection';
import 'downloadable.dart';

abstract class DownloadableQueue<T> extends Downloadable {
  DownloadableQueue(DateTime createDate) : super('', '', createDate);
  final Queue<T> _queue = Queue();

  Queue<T> get queue => _queue;
}
