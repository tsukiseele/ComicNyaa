/*
 * Copyright (C) 2022. TsukiSeele
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

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
    try {
      onProgress?.call(bytes.length, total);
      await for (final value in response.stream) {
        bytes.addAll(value);
        onProgress?.call(bytes.length, total);
      }
      onProgress?.call(bytes.length, total);
      File(path).writeAsBytes(bytes);
    } catch(e) {
      rethrow;
    } finally {
      client.close();
    }
  }

  static Future<void> downloadFileBreakPointer(
    String url,
    String savePath, {
    Map<String, String>? headers,
    void Function(int received, int total)? onProgress,
  }) async {
    int downloadStart = 0;
    File f = File(savePath);
    if (await f.exists()) {
      // 文件存在时拿到已下载的字节数
      downloadStart = await f.length();
    }
    File file = File('$savePath$tempFileSuffix');
    if (await file.exists()) {
      downloadStart = await file.length();
    } else {
      await file.create(recursive: true);
    }
    final request = http.Request('GET', Uri.parse(url));
    headers ??= <String, String>{};
    headers['range'] = 'bytes=$downloadStart-';
    request.headers.addAll(headers);
    final response = await client.send(request);
    RandomAccessFile raf = await file.open(mode: FileMode.append);
    int received = downloadStart;
    final total = (response.contentLength ?? 0) + downloadStart;
    try {
      onProgress?.call(received, total);
      await for (final bytes in response.stream) {
        await raf.writeFrom(bytes);
        received += bytes.length;
        onProgress?.call(received, total);
      }
      onProgress?.call(received, total);
      file.rename(savePath.replaceAll(tempFileSuffix, ''));
    } catch (error) {
      // file.delete();
      rethrow;
    } finally {
      await raf.close();
      client.close();
    }
  }
}
