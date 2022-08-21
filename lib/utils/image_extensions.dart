import 'dart:async';
import 'package:flutter/cupertino.dart';

class ImageUtil {
  Future<ImageInfo> getImageInfo(ImageProvider image) async {
    final c = Completer<ImageInfo>();
    image.resolve(const ImageConfiguration()).addListener(ImageStreamListener((ImageInfo i, bool _) => c.complete(i)));
    return c.future;
  }
}