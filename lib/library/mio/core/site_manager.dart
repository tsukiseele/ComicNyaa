import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:comic_nyaa/library/mio/model/data_origin.dart';

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
      {String suffix = '.zip'}) async {
    final sites = <Site>[];
    await for (final file in dir.list()) {
      final isAllow = file.path.endsWith(suffix);
      if (isAllow) {
        final bytes = File(file.path).readAsBytesSync();
        final archive = ZipDecoder().decodeBytes(bytes);
        for (final entry in archive) {
          if (entry.isFile) {
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
