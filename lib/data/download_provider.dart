import 'dart:io';

import 'package:comic_nyaa/data/download/nyaa_download_task_queue.dart';
import 'package:comic_nyaa/utils/extensions.dart';
import 'package:sqflite/sqflite.dart';

const String tableDownload = 'download';
const String columnId = 'id';
const String columnDirectory = 'directory';
const String columnTitle = 'title';
const String columnCover = 'cover';
const String columnPath = 'path';
const String columnUrl = 'url';
const String columnLevel = 'level';
const String columnParent = 'parent';
const String columnStatus = 'status';

const String createTableDownload = '''
        create table $tableDownload ( 
          $columnId INTEGER PRIMARY KEY AUTOINCREMENT, 
          $columnTitle TEXT NOT NULL,
          $columnCover TEXT NOT NULL,
          $columnDirectory TEXT NOT NULL,
          $columnLevel INTEGER NOT NULL,
          $columnParent TEXT NOT NULL,
          $columnPath TEXT NOT NULL,
          $columnStatus TEXT NOT NULL,
          $columnUrl TEXT NOT NULL)
        ''';

class DownloadProvider {
  late Database _db;

  Future<DownloadProvider> open(String path) async {
    _db = await openDatabase(Directory(path).join('nyaa.db').path, version: 5,
        onCreate: (Database db, int version) async {
      await db.execute(createTableDownload);
    }, onDowngrade: (Database db, int oldVersion, int newVersion) async {
      await db.execute(createTableDownload);
    });
    return this;
  }

  Future<int> insert(NyaaDownloadTaskQueue task) async {
    print('DB_INSERT::: ${task.toJson().toString()}');
    await _db.transaction((txn) async {
      task.id = await txn.insert(tableDownload, task.toJson());
    });
    print('DB_INSERT_KEY_ID::: ${task.id!}');
    return task.id!;
  }

  Future<NyaaDownloadTaskQueue?> getTask(int id) async {
    List<Map> maps = await _db.query(tableDownload,
        columns: [columnId, columnCover, columnTitle],
        where: '$columnId = ?',
        whereArgs: [id]);
    if (maps.isNotEmpty) {
      return NyaaDownloadTaskQueue.fromJson(maps.first as Map<String, dynamic>);
    }
    return null;
  }
  Future<List<NyaaDownloadTaskQueue>> getTasks() async {
    List<Map<String, dynamic>> maps = await _db.query(tableDownload);
    return maps.map((item) => NyaaDownloadTaskQueue.fromJson(item)).toList();
    // if (maps.isNotEmpty) {
    //   return NyaaDownloadTaskQueue.fromJson(maps.first as Map<String, dynamic>);
    // }
    // return null;
  }

  Future<int> delete(int id) async {
    return await _db
        .delete(tableDownload, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> update(NyaaDownloadTaskQueue task) async {
    return await _db.update(tableDownload, task.toJson(),
        where: '$columnId = ?', whereArgs: [task.id]);
  }

  Future close() async => _db.close();
}
