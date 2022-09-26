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

import 'dart:convert';

import '../core/mio.dart';
import '../model/tag.dart';

class YandereAutosuggest {
  static final YandereAutosuggest _instance = YandereAutosuggest._();

  static YandereAutosuggest get instance => _instance;

  YandereAutosuggest._();

  List<Tag> tags = [];

  Future<List<Tag>> queryAutoSuggest(String query,
      {int? limit}) async {
    final lastWordIndex = query.lastIndexOf(' ');
    final word = query.substring(lastWordIndex > 0 ? lastWordIndex : 0);
    if (tags.isEmpty) {
      final json = await Mio.requestAsText('https://yande.re/tag/summary.json');
      tags = queryAllSuggest(json);
    }
    final suggests = <Tag>[];
    for (var tag in tags) {
      if (tag.label.startsWith(word)) {
        suggests.add(tag);
        if (limit != null && suggests.length >= limit) break;
      }
    }
    suggests.sort((a, b) => a.label.compareTo(b.label));
    return suggests;
  }

  List<Tag> queryAllSuggest(String json) {
    final tags = <Tag>[];
      // final json = await Mio.requestAsText('https://yande.re/tag/summary.json');
      final result = Map<String, dynamic>.from(jsonDecode(json));
      final version = result['version'];
      final data = result['data'] as String;
      final kvs = data.split(' ');
      // print('KVS: $kvs' );
      for (var item in kvs) {
        final entry = item.split('`');
        if (entry.length > 1) {
          tags.add(Tag(
              typeCode: int.parse(entry[0]),
              label: entry[1],
              alias: entry.length > 2 ? entry[2] : null));
        }
      }
    return tags;
  }
}
