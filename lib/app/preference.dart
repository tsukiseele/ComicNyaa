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

import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DownloadResourceLevel {
  low('LOW'),
  medium('MEDIUM'),
  high('HIGH');

  const DownloadResourceLevel(this.value);

  final String value;

  static DownloadResourceLevel fromDbValue(String value) =>
      DownloadResourceLevel.values.firstWhere((item) => item.value == value);
}

class NyaaPreferences {
  NyaaPreferences._(this.preferences);

  static NyaaPreferences? _instance;

  static Future<NyaaPreferences> get instance async {
    return _instance ??=
        NyaaPreferences._(await SharedPreferences.getInstance());
  }

  static const defaultDownloadResourceLevel = DownloadResourceLevel.medium;

  final SharedPreferences preferences;

  DownloadResourceLevel get downloadResourceLevel {
    final level = preferences.getString('download_resource_level');
    return DownloadResourceLevel.values
        .singleWhereOrNull((item) => item.value == level) ??
        defaultDownloadResourceLevel;
  }
}
