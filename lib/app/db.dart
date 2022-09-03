import 'dart:io';

import 'package:comic_nyaa/utils/extensions.dart';
import 'package:sqflite/sqflite.dart';

class Db {
  Db._();
  static Db? _instance;
  static Future<Db> get instance async {
    return _instance ??= await Db._initialized();
  }

  static Future<Db> _initialized() async {
    final databasesPath = await getDatabasesPath();
    final path = Directory(databasesPath).join('nyaa.db').path;

    await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
          // When creating the db, create the table
          await db.execute(
              'CREATE TABLE Download (id INTEGER PRIMARY KEY, name TEXT, cover TEXT, url TEXT, path TEXT)');
        });
    return Db._();
  }

}