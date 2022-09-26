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

import 'package:tuple/tuple.dart';

class Tag {
  String label;
  int? typeCode;
  String? type;
  String? color;
  String? count;
  String? alias;

  Tag(
      {required this.label,
      this.typeCode,
      this.type,
      this.color,
      this.count,
      this.alias}) {
    if (typeCode != null) {
      final data = getTypeByCode(typeCode!);
      type ??= data.item1;
      color ??= data.item2;
    }
  }

  Tuple2<String, String> getTypeByCode(int code) {
    switch (code) {
      case 0:
        return const Tuple2('General', '#0075f8');
      case 1:
        return const Tuple2('Artist', '#c00004');
      case 3:
        return const Tuple2('Copyright', '#a800aa');
      case 4:
        return const Tuple2('Character', '#00ab2c');
      case 5:
        return const Tuple2('Meta', '#007f7f');
      default:
        return const Tuple2('Unknown', '#cd5da0');
    }
  }
}
