import 'dart:developer';
import 'dart:io';
import 'nyaa_client.dart';
import 'package:http/http.dart' as http;

class Http {
  static const String tempFileSuffix = '.temp';

  Http._();

  static NyaaClient? _http;

  static NyaaClient get client => _http ??= NyaaClient();

  static Future<void> downloadFile(String url, String path,
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

  static Future<void> downloadFileBreakPointer(
    String url,
    String savePath, {
    Map<String, String>? headers,
    void Function(int received, int total)? onProgress,
    // void Function()? done,
  }) async {
    int downloadStart = 0;
    File f = File(savePath);
    if (await f.exists()) {
      // 文件存在时拿到已下载的字节数
      downloadStart = await f.length();
    }
    // print("start: $downloadStart");
      File file = File('$savePath$tempFileSuffix');
      print('HTTP::: downloadFileBreakPointer ==> OPEN: $file');
      // print('ZZZZZZZZZZZZZZZZZZZZ');
      if (await file.exists()) {
        downloadStart = await file.length();
      } else {
        // print('99999999999');
        await file.create(recursive: true);
      }
      final request = http.Request('GET', Uri.parse(url));
      headers ??= <String, String>{};
      headers['range'] = 'bytes=$downloadStart-';
      request.headers.addAll(headers);
      final response = await client.send(request);
      print('START::: $downloadStart');
      // print('XXXXXXXXXXXXXXXXXX');
      RandomAccessFile raf = await file.open(mode: FileMode.append);
      // print('AAAAAAAAAAAAAAAAAAAAAAA');
      int received = downloadStart;
      final total = response.contentLength ?? 0;
      try {
        onProgress?.call(received, total);
        // print('BVBBBBBBBBBBBBBBBB');
        await for (final bytes in response.stream) {
          await raf.writeFrom(bytes);
          received += bytes.length;
          onProgress?.call(received, total);
          // print('CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC');
        }
        onProgress?.call(received, total);
        file.rename(savePath.replaceAll(tempFileSuffix, ''));
        // done?.call();
      } catch (error) {
        // file.delete();
        // print('EEEEEEEEEEEEEEEEEEEEE::: $error');
        rethrow;
      } finally {
        await raf.close();
        client.close();
      }
      // Stream<Uint8List> stream = response.data!.stream;
      // StreamSubscription<Uint8List>? subscription;
      // subscription = stream.listen(
      //       (data) {
      //     /// Write files must be synchronized
      //     raf.writeFromSync(data);
      //     received += data.length;
      //     onReceiveProgress?.call(received, total);
      //   },
      //   onDone: () async {
      //     file.rename(savePath.replaceAll('.temp', ''));
      //     await raf.close();
      //     done?.call();
      //   },
      //   onError: (e) async {
      //     await raf.close();
      //     failed?.call(e);
      //   },
      //   cancelOnError: true,
      // );
      // cancelToken.whenCancel.then((_) async {
      //   await subscription?.cancel();
      //   await raf.close();
      // });
  }
}
