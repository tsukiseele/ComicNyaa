import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';

import '../model/site.dart';

class RuleLoader {
  static final Map<int, Site> _sites = {};

  RuleLoader._();

  static Map<int, Site> get sites {
    return _sites;
  }
  static Site? getSiteById(int id) {
    return _sites[id];
  }
  static List<Site> getSitesByType(String type) {
    return sites.values.toList().where((element) => element.type == type).toList();
  }



  static Future<List<Site>> loadFromDirectory(Directory dir, {String suffix = '.zip'}) async {
    final sites = <Site>[];
    await for (final file in dir.list()) {
      final isAllow = file.path.endsWith(suffix);
      if (isAllow) {
        final bytes = File(file.path).readAsBytesSync();
        final archive = ZipDecoder().decodeBytes(bytes);
        for (final file in archive) {
          if (file.isFile) {
            final json = jsonDecode(utf8.decode(file.content));
            final jsonMap = Map<String, dynamic>.from(json);
            final site = Site.fromJson(jsonMap);
            sites.add(site);
            if (site.id != null) {
              _sites[site.id!] = site;
            }
          }
        }
      }
    }
    return sites;
  }
}