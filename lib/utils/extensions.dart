import 'dart:io';

import 'package:comic_nyaa/models/typed_model.dart';
import 'package:comic_nyaa/utils/uri_extensions.dart';

import '../app/app_preference.dart';

extension ExtendedPath on FileSystemEntity {
  Directory joinDir(Directory child) {
    return Directory(join(child.path));
  }

  File joinFile(Directory child) {
    return File(join(child.path));
  }

  String join(String child) {
    return '$path${Platform.pathSeparator}$child';
  }
}

extension TypedModelExt on TypedModel {
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
    return url ?? '';
  }

  String get availablePreviewUrl {
    String? url;
    if (children != null) {
      final first = children!.first;
      url = first.sampleUrl ?? first.largerUrl ?? first.originUrl;
    }
    url = url ?? sampleUrl ?? largerUrl ?? originUrl;

    return Uri.encodeFull(url ?? '').asUrl;
  }

  String get availableCoverUrl {
    String? url;
    if (children != null) {
      final first = children!.first;
      url = first.coverUrl ??
          first.sampleUrl ??
          first.largerUrl ??
          first.originUrl;
    }
    url = url ?? coverUrl ?? sampleUrl ?? largerUrl ?? originUrl;
    return url?.asUrl ?? '';
  }


  isSni() async {
    final df = getOrigin().site.domainFronting;
    final locale = (await AppPreferences.instance).locale;
    if (locale == df?.country) {
      return true;
    }
    return false;
  }
}
