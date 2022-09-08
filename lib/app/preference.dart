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
