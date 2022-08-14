extension UriExtension on Uri {
  String decodeComponentDeep() {
    String uri = toString();
    while (uri.contains('%25')) {
      uri = Uri.decodeComponent(uri);
    }
    return Uri.decodeComponent(uri);
  }

  String filename() {
    return Uri.parse(toString().split("/").last.split('?').first).decodeComponentDeep();
  }
}
