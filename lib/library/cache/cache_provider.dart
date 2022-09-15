import 'dart:typed_data';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CacheProvider {
  CacheProvider(String key) {
    _cacheManager = CacheManager(
      Config(
        key,
        stalePeriod: const Duration(minutes: 15),
        maxNrOfCacheObjects: 512,
      ),
    );
  }

  late final CacheManager _cacheManager;

  bool put(String key, Uint8List bytes) {
    _cacheManager.putFile(key, bytes, eTag: key);
    return true;
  }

  Future<Uint8List?> get(String key) async {
    final fileInfo = await _cacheManager.getFileFromCache(key);
    return await fileInfo?.file.readAsBytes();
  }
  Future<String?> getAsString(String key) async {
    final fileInfo = await _cacheManager.getFileFromCache(key);
    return await fileInfo?.file.readAsString();
  }
}
