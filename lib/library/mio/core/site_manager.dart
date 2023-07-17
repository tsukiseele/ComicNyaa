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
import 'dart:io';
import 'dart:math';

import 'package:archive/archive.dart';
import '../model/data_origin.dart';

import '../model/site.dart';

class SiteManager {
  static final Map<int, Site> _sites = {};
  static final Map<String, List<Site>> _targetInfo = {};

  SiteManager._();
  /// 获取所有Site的集合
  static Map<int, Site> get sites {
    return _sites;
  }
  /// 获取所有指定类型的Site集合
  static List<Site> getSitesByType(String type) {
    return sites.values
        .where((element) => element.type == type)
        .toList();
  }
  /// 从SiteID获取Site对象
  static Site? getSiteById(int id) {
    return _sites[id];
  }
  /// 从来源信息获取Site对象
  ///
  static Site? getSiteByOriginInfo(DataOriginInfo dataOrigin) {
    return getSiteById(dataOrigin.siteId!);
  }
  /// 规则的源信息，包括路径或者URL信息
  ///
  static Map<String, List<Site>> get targetInfo {
    return _targetInfo;
  }
  /// 从目录加载规则，默认加载所有.zip文件（不递归）
  ///
  static Future<List<Site>> loadFromDirectory(Directory dir,
      {String suffix = '.zip', String ruleSuffix = '.json'}) async {
    final sites = <Site>[];
    await for (final file in dir.list()) {
      final isAllow = file.path.endsWith(suffix);
      if (isAllow) {
        final bytes = File(file.path).readAsBytesSync();
        final archive = ZipDecoder().decodeBytes(bytes);
        for (final entry in archive) {
          if (entry.isFile && entry.name.endsWith(ruleSuffix)) {
            print(entry.name);
            final json = jsonDecode(utf8.decode(entry.content));
            final jsonMap = Map<String, dynamic>.from(json);
            final site = Site.fromJson(jsonMap);
            sites.add(site);
            if (site.id != null) _sites[site.id!] = site;
            if (_targetInfo[file.path] == null) _targetInfo[file.path] = [];
            _targetInfo[file.path]!.add(site);
          }
        }
      }
    }
    return sites;
  }
}
