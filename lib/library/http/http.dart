import 'dart:io';

import 'nyaa_client.dart';

import 'package:http/http.dart' as http;

class Http {
  Http._();

  static NyaaClient? _http;

  static NyaaClient get client => _http ??= NyaaClient();

  // static Dio client() {
  //   _dio ??= Dio(BaseOptions(
  //     sendTimeout: 10000,
  //     connectTimeout: 15000,
  //     receiveTimeout: 20000,
  //   ));
  //   // _dio?.interceptors.add(QueuedInterceptor());
  //   _dio?.interceptors.add(DioCacheManager(CacheConfig(defaultMaxAge: const Duration(minutes: 15))).interceptor);
  //   _dio?.interceptors.add(RetryInterceptor(
  //     dio: _dio!,
  //     logPrint: print, // specify log function (optional)
  //     retries: 3, // retry count (optional)
  //     retryDelays: const [ // set delays between retries (optional)
  //       Duration(seconds: 1), // wait 1 sec before first retry
  //       Duration(seconds: 2), // wait 2 sec before second retry
  //       Duration(seconds: 3), // wait 3 sec before third retry
  //     ],
  //   ));
  //
  //   return _dio!;
  // }

  static Future<void> download(String url, String path,
      {Map<String, String>? headers,
      void Function(int received, int total)? onProgress}) async {
    final request = http.Request('GET', Uri.parse(url));
    if (headers != null) request.headers.addAll(headers);
    final response = await client.send(request);
    final total = response.contentLength ?? 0;
    final List<int> bytes = [];
    await for (final value in response.stream) {
      bytes.addAll(value);
      if (onProgress != null) onProgress(bytes.length, total);
    }
    if (onProgress != null) onProgress(bytes.length, total);
    client.close();
    File(path).writeAsBytes(bytes);
  }

/*
  Future<void> downloadFile({
    required String url,
    required String savePath,
    required CancelToken cancelToken,
    ProgressCallback? onReceiveProgress,
    void Function()? done,
    void Function(Exception)? failed,
  }) async {
    int downloadStart = 0;
    File f = File(savePath);
    if (await f.exists()) {
      // 文件存在时拿到已下载的字节数
      downloadStart = f.lengthSync();
    }
    print("start: $downloadStart");
    try {
      var response = await downloadDio.get<ResponseBody>(
        url,
        options: Options(
          /// Receive response data as a stream
          responseType: ResponseType.stream,
          followRedirects: false,
          headers: {
            /// 加入range请求头，实现断点续传
            "range": "bytes=$downloadStart-",
          },
        ),
      );
      File file = File(savePath);
      RandomAccessFile raf = file.openSync(mode: FileMode.append);
      int received = downloadStart;
      int total = await _getContentLength(response);
      Stream<Uint8List> stream = response.data!.stream;
      StreamSubscription<Uint8List>? subscription;
      subscription = stream.listen(
            (data) {
          /// Write files must be synchronized
          raf.writeFromSync(data);
          received += data.length;
          onReceiveProgress?.call(received, total);
        },
        onDone: () async {
          file.rename(savePath.replaceAll('.temp', ''));
          await raf.close();
          done?.call();
        },
        onError: (e) async {
          await raf.close();
          failed?.call(e);
        },
        cancelOnError: true,
      );
      cancelToken.whenCancel.then((_) async {
        await subscription?.cancel();
        await raf.close();
      });
    } on DioError catch (error) {
      if (CancelToken.isCancel(error)) {
        print("Download cancelled");
      } else {
        failed?.call(error);
      }
    }
  }*/
}
