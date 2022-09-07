import 'dart:io';

import 'package:http/http.dart' as http;

class HClient extends http.BaseClient {
  final http.Client _inner;

  HClient(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _inner.send(request);
  }

  static Future<void> download(String url, String path, Function(int received, int total)? progress) async {
    final request = http.Request('GET', Uri.parse(url));
    final client = http.Client();
    final response = await client.send(request);
    final total = response.contentLength ?? 0;
    final List<int> bytes = [];
    await for (final value in response.stream) {
      bytes.addAll(value);
      if (progress != null) progress(bytes.length, total);
    }
    client.close();
    File(path).writeAsBytes(bytes);
  }
}
