import 'package:dio/dio.dart';

class Http {
  Http._();

  static Dio? dio;

  static Dio client() {
    dio ??= Dio(BaseOptions(
      sendTimeout: 10000,
      connectTimeout: 15000,
      receiveTimeout: 20000,
    ));
    return dio!;
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
