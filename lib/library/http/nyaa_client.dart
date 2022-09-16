import 'dart:io';

import 'package:comic_nyaa/library/http/http_timeout_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:http/retry.dart';

class NyaaClient extends http.BaseClient {
  NyaaClient({int connectionTimeout = 15000, int idleTimeout = 15000}) {
    final client = HttpClient();
    // client.
    _inner = RetryClient(IOClient(HttpTimeoutClient(client,
            connectionTimeout: connectionTimeout, idleTimeout: idleTimeout)
        .client));
  }

  late http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner.send(request);
    return response;
  }
}
