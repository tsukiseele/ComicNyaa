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

import 'package:comic_nyaa/library/mio/core/mio.dart';
import 'package:comic_nyaa/library/mio/label/autosuggest.dart';

import '../model/tag.dart';

class YandereAutosuggest extends AutoSuggest {
  static final YandereAutosuggest _instance = YandereAutosuggest._();

  factory YandereAutosuggest() => _instance;

  YandereAutosuggest._();

  List<Tag> tags = [];

  dynamic _getTypeByCode(int code) {
    switch (code) {
      case 0:
        return {'type': 'General', 'color': '#0075f8'};
      case 1:
        return {'type': 'Artist', 'color': '#c00004'};
      case 3:
        return {'type': 'Copyright', 'color': '#a800aa'};
      case 4:
        return {'type': 'Character', 'color': '#00ab2c'};
      case 5:
        return {'type': 'Meta', 'color': '#007f7f'};
      default:
        return {'type': 'Unknown', 'color': '#cd5da0'};
    }
  }

  @override
  Future<List<Tag>> queryAutoSuggest(String query) async {
    final lastWordIndex = query.lastIndexOf(' ');
    final word = query.substring(lastWordIndex > 0 ? lastWordIndex : 0);
    //
    if (tags.isEmpty) {
      final json = await Mio.requestAsText('https://yande.re/tag/summary.json');
      final result = Map<String, dynamic>.from(jsonDecode(json));
      final version = result['version'];
      final data = result['data'] as String;
      final kvs = data.split(' ');
      print('KVS: $kvs' );
      for (var item in kvs) {
        final entry = item.split('`');
        // print(entry);
        if (entry.length > 1) {
          final tag = Tag();
          final typeEntry = _getTypeByCode(int.parse(entry[0]));
          tag.type = typeEntry['type'];
          tag.color = typeEntry['color'];
          tag.label = entry[1];
          tags.add(tag);
        }
      }}
    print('TAGS: $tags' );
    return tags.where((tag) => tag.label.contains(word)).toList();
  }
}
