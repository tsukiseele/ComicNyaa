import 'dart:io';

import 'package:path_provider/path_provider.dart';

extension ExtendedPath on Directory {
  Directory concatDir(Directory child) {
    return concatPath(child.path);
  }
  Directory concatPath(String child) {
    return Directory('$path${Platform.pathSeparator}$child');
  }
}
class Config {
  Config();

  static Directory? _appDir;
  static Directory? _ruleDir;

  static Future<Directory> get appDir async {
    _appDir = _appDir ?? await getApplicationDocumentsDirectory();
    return _appDir!;
  }

  static Future<Directory> get ruleDir async {
    _ruleDir = _ruleDir ?? (await appDir).concatPath('rules');
    await _ruleDir?.create(recursive: true);
    return _ruleDir!;
  }
}