import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/src/foundation/key.dart';

extension DynamicImage on CachedNetworkImage {
  network(imageUrl) {
    return CachedNetworkImage(imageUrl: imageUrl);
  }
}