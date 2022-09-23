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

class DanbooruAutosuggest extends AutoSuggest {
  static final DanbooruAutosuggest _instance = DanbooruAutosuggest._();
  factory DanbooruAutosuggest() => _instance;
  DanbooruAutosuggest._();

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
    final text = await Mio.requestAsText(
        'https://danbooru.donmai.us/autocomplete.json?search[query]=$word&search[type]=tag_query&limit=15');
    final result = List<Map<String, dynamic>>.from(jsonDecode(text));
    final suggests = <Tag>[];
    for (final item in result) {
      final suggest = Tag();
      final typeEntry = _getTypeByCode(item['category']);
      suggest.label = item['value'];
      suggest.count = item['post_count'].toString();
      suggest.type = typeEntry['type'];
      suggest.color = typeEntry['color'];
      suggests.add(suggest);
    }
    return suggests;
  }
}
