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

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:comic_nyaa/library/mio/label/autosuggest.dart';
import 'package:comic_nyaa/library/mio/model/tag.dart';
import 'package:sqflite/sqflite.dart';

class SearchAutoSuggest extends TagAutoSuggest {
  static const databaseName = 'tags.db';
  static const tableName = 'tags';
  static const columnTag = 'tag';
  static const columnAlias = 'tag';
  static final assetsDatabasePath = path.join('assets', 'data', databaseName);

  SearchAutoSuggest._();

  static SearchAutoSuggest? _instance;

  static SearchAutoSuggest get instance => _instance ??= SearchAutoSuggest._();

  Database? _db;

  Future<Database> getAndCreateDatabaseFromAssets() async {
    final databasesPath = await getDatabasesPath();
    final cpPath = path.join(databasesPath, databaseName);

    // Check if the database exists
    final exists = await databaseExists(cpPath);

    if (!exists) {
      // Should happen only the first time you launch your application
      print("Creating new copy from asset");

      // Make sure the parent directory exists
      try {
        await Directory(path.dirname(cpPath)).create(recursive: true);
      } catch (_) {}

      // Copy from asset
      ByteData data = await rootBundle.load(assetsDatabasePath);
      List<int> bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      // Write and flush the bytes written
      await File(cpPath).writeAsBytes(bytes, flush: true);
    } else {
      print("Opening existing database");
    }
    // open the read only database
    return await openReadOnlyDatabase(cpPath);
  }

  Future<Database> getDatabase() async {
    if (_db != null) return _db!;
    return _db ??= await getAndCreateDatabaseFromAssets();
  }

  @override
  Future<List<Tag>> queryAutoSuggest(String query, {int? limit}) async {
    final db = await getDatabase();
    query = query.replaceAll('_', '\\_').replaceAll('%', '\\%').replaceAll('[', '\\[');
    final result = await db.rawQuery(
        'SELECT * FROM $tableName WHERE $columnTag LIKE \'%$query%\' ESCAPE \'\\\' OR $columnAlias LIKE \'%$query%\' ESCAPE \'\\\' ${limit != null ? ' LIMIT $limit' : ''}');
    return result.map((item) {
      return Tag(label: item['tag'] as String, typeCode: item['type'] as int, alias: item['alias'] as String);
    }).toList();
  }
}
