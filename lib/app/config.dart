import 'dart:io';

import 'package:comic_nyaa/utils/extensions.dart';
import 'package:path_provider/path_provider.dart';

class Config {
  Config._();
  static const appName = 'ComicNyaa';
  static const uiFontFamily = null; //'sans-serif';

  static const downloadDirectoryName = 'ComicNyaa';
  static const rulesDirectoryName = 'rules';
  static Directory? _appDir;
  static Directory? _ruleDir;
  static Directory? _downloadDir;

  static Future<Directory> get appDir async {
    _appDir = _appDir ?? await getApplicationDocumentsDirectory();
    return _appDir!;
  }

  static Future<Directory> get ruleDir async {
    _ruleDir = _ruleDir ?? (await appDir).join(rulesDirectoryName);
    await _ruleDir?.create(recursive: true);
    return _ruleDir!;
  }

  static Future<Directory> get downloadDir async {
    _downloadDir = _downloadDir ?? (await _getDownloadPath())?.join(downloadDirectoryName);
    await _downloadDir?.create(recursive: true);
    return _downloadDir!;
  }
}

Future<Directory?> _getDownloadPath() async {
  Directory? directory;
  try {
    if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    } else {
      directory = Directory('/storage/emulated/0/Download');
      // Put file in global download folder, if for an unknown reason it didn't exist, we fallback
      // ignore: avoid_slow_async_io
      if (!await directory.exists()) directory = await getExternalStorageDirectory();
    }
  } catch (err, stack) {
    print("Cannot get download folder path");
  }
  return directory;
}