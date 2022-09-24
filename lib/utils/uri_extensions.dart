extension UriExtension on Uri {
  String decodeComponentDeep() {
    String uri = toString();
    while (uri.contains('%25')) {
      uri = Uri.decodeComponent(uri);
    }
    return Uri.decodeComponent(uri);
  }

  String get filename {
    return Uri.parse(toString().split("/").last.split('?').first).decodeComponentDeep();
  }

}

extension UrlBuilder on String {
  get asUrl {
    return replaceAll(r'\', '');
  }
}
