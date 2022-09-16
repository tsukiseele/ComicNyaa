/*
 * Copyright (C) 2022. TsukiSeele
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:async';
import 'dart:collection';

class TaskRunner<A, B> {
  final Queue<A> _input = Queue();
  final StreamController<B> _streamController = StreamController();
  final Future<B> Function(A) task;

  final int maxConcurrentTasks;
  int runningTasks = 0;

  TaskRunner(this.task, {this.maxConcurrentTasks = 5});

  Stream<B> get stream => _streamController.stream;

  void add(A value) {
    _input.add(value);
    _startExecution();
  }

  void addAll(Iterable<A> iterable) {
    _input.addAll(iterable);
    _startExecution();
  }

  void _startExecution() {
    if (runningTasks == maxConcurrentTasks || _input.isEmpty) {
      return;
    }

    while (_input.isNotEmpty && runningTasks < maxConcurrentTasks) {
      runningTasks++;
      print('Concurrent workers: $runningTasks');

      task(_input.removeFirst()).then((value) async {
        _streamController.add(value);

        while (_input.isNotEmpty) {
          _streamController.add(await task(_input.removeFirst()));
        }

        runningTasks--;
        print('Concurrent workers: $runningTasks');
      });
    }
  }
}