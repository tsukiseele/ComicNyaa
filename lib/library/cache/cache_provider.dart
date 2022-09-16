import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CacheProvider {
  CacheProvider(String name,
      {this.maxAge = const Duration(minutes: 15),
      this.maxCacheSize = 128,
      this.enableGZip = false}) {
    _cacheManager = CacheManager(
      Config(
        name,
        stalePeriod: maxAge,
        maxNrOfCacheObjects: maxCacheSize,
      ),
    );
  }

  late final CacheManager _cacheManager;
  final Duration maxAge;
  final int maxCacheSize;
  final bool enableGZip;

  bool put(String key, Uint8List bytes) {
    try {
      if (enableGZip) {
        bytes = Uint8List.fromList(GZipEncoder().encode(bytes)!);
      }
      _cacheManager.putFile(key, bytes, eTag: key, maxAge: maxAge);
    } catch (e) {
      print('CACHE ERROR::: key=$key');
    }
    return true;
  }

  Future<Uint8List?> get(String key) async {
    final fileInfo = await _cacheManager.getFileFromCache(key);
    final bytes = await fileInfo?.file.readAsBytes();
    if (enableGZip) {
      return bytes != null
          ? Uint8List.fromList(GZipDecoder().decodeBytes(bytes))
          : null;
    } else {
      return bytes;
    }
  }

  Future<String?> getAsString(String key) async {
    final bytes = await get(key);
    return bytes != null ? utf8.decode(bytes) : null;
  }
}
