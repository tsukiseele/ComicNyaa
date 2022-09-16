import 'package:comic_nyaa/library/cache/cache_provider.dart';

class HttpCache {
  HttpCache._();
  static final CacheProvider instance = CacheProvider('HttpCache', maxCacheSize: 512, enableGZip: true);
}