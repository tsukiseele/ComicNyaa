import 'package:dio/dio.dart';
import 'package:dio_http_cache/dio_http_cache.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';

class Http {
  Http._();

  static Dio? _dio;

  static Dio client() {
    _dio ??= Dio(BaseOptions(
      sendTimeout: 10000,
      connectTimeout: 15000,
      receiveTimeout: 20000,
    ));
    // _dio?.interceptors.add(QueuedInterceptor());
    // _dio?.interceptors.add(DioCacheManager(CacheConfig(defaultMaxAge: const Duration(seconds: 15))).interceptor);
    _dio?.interceptors.add(RetryInterceptor(
      dio: _dio!,
      logPrint: print, // specify log function (optional)
      retries: 3, // retry count (optional)
      retryDelays: const [ // set delays between retries (optional)
        Duration(seconds: 1), // wait 1 sec before first retry
        Duration(seconds: 2), // wait 2 sec before second retry
        Duration(seconds: 3), // wait 3 sec before third retry
      ],
    ));

    return _dio!;
  }

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onReceiveProgress,
  }) async {
    return await client().get(path,
        queryParameters: queryParameters, options: options, cancelToken: cancelToken, onReceiveProgress: onReceiveProgress);
  }
}
