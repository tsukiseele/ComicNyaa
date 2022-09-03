import 'dart:io';

import 'package:comic_nyaa/models/typed_model.dart';

import '../app/preference.dart';

extension ExtendedPath on Directory {
  Directory joinDir(Directory child) {
    return join(child.path);
  }
  Directory join(String child) {
    return Directory('$path${Platform.pathSeparator}$child');
  }
}

extension TypedModelEx on TypedModel {
  String getUrl(DownloadResourceLevel downloadResourceLevel) {
    String? url;
    switch (downloadResourceLevel) {
      case DownloadResourceLevel.low:
        url = sampleUrl ?? largerUrl ?? originUrl;
        break;
      case DownloadResourceLevel.medium:
        url = largerUrl ?? originUrl ?? sampleUrl;
        break;
      case DownloadResourceLevel.high:
        url = originUrl ?? largerUrl ?? sampleUrl;
        break;
    }
    if (url == null || url.trim().isEmpty) {
      return '';
    }
    return url;
  }
}
