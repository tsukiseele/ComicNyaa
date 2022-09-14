import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class HttpCacheManager {
  HttpCacheManager._();
  
  static const key = 'httpCacheKey';
  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(milliseconds: 15),
      maxNrOfCacheObjects: 512,
      repo: JsonCacheInfoRepository(databaseName: key),
      // fileSystem: IOFileSystem(key),
      // fileService: HttpFileService(),
    ),
  );
}
