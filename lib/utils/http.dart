import 'package:dio/dio.dart';

class Http {
  Http._();

  static final dio = Dio(BaseOptions(
    baseUrl: 'https://www.xx.com/api',
    connectTimeout: 5000,
    receiveTimeout: 3000,
  ));

  static client() {
    return dio;
  }

  static Future<Response<dynamic>> get(String path,
      { Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken, void Function(int, int)? onReceiveProgress,}) async {
    return await dio.get(path, queryParameters: queryParameters, options: options, cancelToken: cancelToken, onReceiveProgress: onReceiveProgress);
  }
}