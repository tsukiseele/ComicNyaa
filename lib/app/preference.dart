import 'package:shared_preferences/shared_preferences.dart';

class DownloadResourceLevel {
  DownloadResourceLevel._();
  static const low = 'low';
  static const middle = 'middle';
  static const high = 'high';
}

class NyaaPreferences {
  NyaaPreferences._(this.preferences);
  static NyaaPreferences? _instance;
  static Future<NyaaPreferences> get instance async {
    return _instance ??= NyaaPreferences._(await SharedPreferences.getInstance());
  }
  static const defaultDownloadResourceLevel = DownloadResourceLevel.middle;

  final SharedPreferences preferences;

  String get downloadResourceLevel {
    return preferences.getString('download_resource_level') ?? defaultDownloadResourceLevel;
  }
}