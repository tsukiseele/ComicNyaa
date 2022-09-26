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
import '../label/autosuggest.dart';

import '../model/tag.dart';

class DanbooruAutosuggest extends TagAutoSuggest {
  static final DanbooruAutosuggest _instance = DanbooruAutosuggest._();

  factory DanbooruAutosuggest() => _instance;

  DanbooruAutosuggest._();

  @override
  Future<List<Tag>> queryAutoSuggest(String query, {int? limit}) async {
    final lastWordIndex = query.lastIndexOf(' ');
    final word = query.substring(lastWordIndex > 0 ? lastWordIndex : 0);
    //
    final text = await Mio.requestAsText(
        'https://danbooru.donmai.us/autocomplete.json?search[query]=$word&search[type]=tag_query&limit=15');
    final result = List<Map<String, dynamic>>.from(jsonDecode(text));
    final suggests = <Tag>[];
    for (final item in result) {
      suggests.add(Tag(
          typeCode: item['category'],
          label: item['value'],
          count: item['post_count'].toString()));
    }
    return suggests;
  }
}
