
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';

import '../model/site.dart';

class RuleLoader {
  RuleLoader._();

  static Future<List<Site>> getRules(Directory dir ) async {

    final sites = <Site>[];
    await for (final file in dir.list()) {
      final isAllow = file.path.endsWith('.zip');
      if (isAllow) {
        final bytes = File(file.path).readAsBytesSync();
        final archive = ZipDecoder().decodeBytes(bytes);
        for (final file in archive) {
          if (file.isFile) {
            final json = jsonDecode(utf8.decode(file.content));
            final jsonMap = Map<String, dynamic>.from(json);
            sites.add(Site.fromJson(jsonMap));
          }
        }
      }
    }
    return sites;
  }
}