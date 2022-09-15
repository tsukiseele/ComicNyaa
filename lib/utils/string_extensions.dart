class StringUtil {
  static String value(String? value, String? defaultValue) {
    return value != null && value.isNotEmpty ? value : defaultValue ?? '';
  }
}