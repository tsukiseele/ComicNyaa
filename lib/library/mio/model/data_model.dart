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

import '../core/site_manager.dart';
import 'data_origin.dart';


const String k$type = r'$type';
const String k$children = r'$children';
const String k$extended = r'$extended';
const String k$origin = r'$origin';
const String k$key = r'$key';

const String fieldChildren = r'children';

/// 抓取数据模型
/// 子类必须实现 toJson() 和 fromJson() 完成序列化
class DataModel<T> {
  String? $type;
  // List<String>? sources;
  List<T>? children; // 需要在子类实现序列化
  String? $children;
  String? $extended;
  DataOriginInfo? $origin;

  DataModel.fromJson(Map<String, dynamic> json) {
    $type = json[k$type];
    $children = json[k$children];
    $extended = json[k$extended];
    $origin = json[k$origin] != null
        ? DataOriginInfo.fromJson(json[k$origin])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data[k$type] = $type;
    data[k$children] = $children;
    data[k$extended] = $extended;
    if ($origin != null) data[k$origin] = $origin!.toJson();
    return data;
  }

  DataOrigin getOrigin() {
    final origin = $origin;
    if (origin == null || !origin.isAvaliable()) {
      throw Exception('Unavailable data origin!');
    }
    final site = SiteManager.getSiteByOriginInfo(origin)!;
    final section = site.sections![origin.sectionName]!;

    return DataOrigin(site, section);
  }
}
