import 'package:comic_nyaa/models/typed_model.dart';

import '../app/preference.dart';

extension TypedModelEx on TypedModel {
  String getUrl(String downloadResourceLevel) {
    String? url;
    switch (downloadResourceLevel) {
      case DownloadResourceLevel.low:
        url = sampleUrl ?? largerUrl ?? originUrl;
        break;
      case DownloadResourceLevel.middle:
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