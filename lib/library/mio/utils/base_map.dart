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

import 'dart:collection';

isEmpty(Object? o) {
  return o == null || o == "";
}

class BaseMap<K, V> extends MapMixin<K, V> {
  Map<K, V> json = <K, V>{};

  @override
  V? operator [](Object? key) {
    return json[key];
  }

  @override
  void operator []=(K key, V value) {
    json[key] = value;
  }

  @override
  void clear() {
    json.clear();
  }

  @override
  // TODO: implement keys
  Iterable<K> get keys => json.keys;

  @override
  V? remove(Object? key) {
    return json.remove(key);
  }

  // BaseMap.fromJson(Map<String, dynamic> json) {
  //   final val = json.map((key, value) => MapEntry(key as K, value as V));
  //   addAll(val);
  // }

  BaseMap<String, dynamic> toJson() => this as BaseMap<String, dynamic>;
}

extension BoolParsing on String {
  bool parseBool() {
    if (toLowerCase() == 'true') {
      return true;
    } else if (toLowerCase() == 'false') {
      return false;
    }
    return false;
    // throw '"$this" can not be parsed to boolean.';
  }
}