import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/retry.dart';

class HClient extends http.BaseClient {
  HClient._(this._inner);

  final http.Client _inner;

  static HClient? _client;

  static HClient get client => _client ??= HClient._(RetryClient(http.Client()));

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.persistentConnection = false;
    return _inner.send(request);
  }

  static Future<void> download(String url, String path, { Map<String, String>? headers, void Function(int received, int total)? onProgress}) async {
    final request = http.Request('GET', Uri.parse(url));
    if (headers != null) request.headers.addAll(headers);
    final response = await client.send(request);
    final total = response.contentLength ?? 0;
    final List<int> bytes = [];
    await for (final value in response.stream) {
      bytes.addAll(value);
      if (onProgress != null) onProgress(bytes.length, total);
    }
    client.close();
    File(path).writeAsBytes(bytes);
  }
}