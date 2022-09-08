import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DownloadResourceLevel {
  low('LOW'),
  medium('MEDIUM'),
  high('HIGH');

  const DownloadResourceLevel(this.value);

  final String value;

  static DownloadResourceLevel fromDbValue(int code) {
    switch (code) {
      case 1:
        return DownloadResourceLevel.low;
      case 2:
        return DownloadResourceLevel.medium;
      case 3:
        return DownloadResourceLevel.high;
      default:
        return DownloadResourceLevel.medium;
    }
  }
  int toDbCode() {
    switch (this) {
      case DownloadResourceLevel.low:
        return 1;
      case DownloadResourceLevel.medium:
        return 2;
      case DownloadResourceLevel.high:
        return 3;
    }
  }
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
