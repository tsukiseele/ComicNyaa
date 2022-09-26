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

import 'package:comic_nyaa/utils/extensions.dart';
import 'package:sqflite/sqflite.dart';

import '../app/config.dart';

const String tableSubscribe = 'subscribe';
const int version = 1;
const String columnId = 'id';
const String columnName = 'name';
const String columnUrl = 'url';
const String columnUpdateDate = 'updateDate';
const String columnVersion = 'version';

const String createTableSubscribe = '''
        CREATE TABLE $tableSubscribe ( 
          $columnId INTEGER PRIMARY KEY AUTOINCREMENT, 
          $columnName TEXT NOT NULL,
          $columnUrl TEXT NOT NULL,
          $columnUpdateDate TEXT NOT NULL,
          $columnVersion INTEGER NOT NULL)
        ''';

class SubscribeProvider {
  late Database _db;

  Future<SubscribeProvider> open() async {
    final path = (await AppConfig.databaseDir).join('$tableSubscribe.db');
    bool isFirstCreated = false;
    _db = await openDatabase(path, version: version,
        onCreate: (Database db, int version) async {
      await db.execute(createTableSubscribe);
      isFirstCreated = true;
    });
    if (isFirstCreated) {
      await insert(Subscribe(
          name: 'Default',
          url: 'https://hlo.li/static/rules.zip',
          version: 1,
          updateDate: DateTime.now().toIso8601String()));
    }
    return this;
  }

  Future<int> insert(Subscribe item) async {
    print('DB_INSERT::: ${item.toJson().toString()}');
    await _db.transaction((txn) async {
      item.id = await txn.insert(tableSubscribe, item.toJson());
    });
    print('DB_INSERT_KEY_ID::: ${item.id!}');
    return item.id!;
  }

  Future<Subscribe?> getSubscribeById(int id) async {
    List<Map> maps = await _db
        .query(tableSubscribe, where: '$columnId = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Subscribe.fromJson(maps.first as Map<String, dynamic>);
    }
    return null;
  }

  Future<List<Subscribe>> getSubscribes() async {
    List<Map<String, dynamic>> maps = await _db.query(
      tableSubscribe,
      orderBy: '$columnUpdateDate DESC',
    );
    return maps.map((item) => Subscribe.fromJson(item)).toList();
  }

  Future<int> deleteById(int id) async {
    return await _db
        .delete(tableSubscribe, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> delete(Subscribe item) async {
    return await _db
        .delete(tableSubscribe, where: '$columnId = ?', whereArgs: [item.id]);
  }

  Future<int> update(Subscribe task) async {
    return await _db.update(tableSubscribe, task.toJson(),
        where: '$columnId = ?', whereArgs: [task.id]);
  }

  Future close() async => _db.close();
}

class Subscribe {
  Subscribe({this.name, this.url, this.version, this.updateDate});

  int? id;
  int? version;
  String? name;
  String? url;
  String? updateDate;

  bool equals(Subscribe s) {
    if (name == s.name && url == s.url) {
      return true;
    }
    return false;
  }

  Subscribe.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    url = json['url'];
    id = json['id'];
    version = json['version'];
    updateDate = json['updateDate'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = {};
    data['id'] = id;
    data['version'] = version;
    data['name'] = name;
    data['url'] = url;
    data['updateDate'] = updateDate;
    return data;
  }
}
