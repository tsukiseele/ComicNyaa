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

enum TagType {
  general('General', '#0075f8'),
  artist('Artist', '#c00004'),
  copyright('Copyright', '#a800aa'),
  character('Character', '#00ab2c'),
  meta('Meta', '#007f7f'),
  unknown('Unknown', '#cd5da0');

  const TagType(this.name, this.color);

  final String name;
  final String color;
}

class Tag {
  String label;
  int? typeCode;
  TagType? type;
  String? count;
  String? alias;

  Tag({required this.label, this.typeCode, this.type, this.count, this.alias}) {
    if (typeCode != null) type = getTypeByCode(typeCode!);
  }

  TagType getTypeByCode(int code) {
    switch (code) {
      case 0:
        return TagType.general;
      case 1:
        return TagType.artist;
      case 3:
        return TagType.copyright;
      case 4:
        return TagType.character;
      case 5:
        return TagType.meta;
      default:
        return TagType.unknown;
    }
  }
}
