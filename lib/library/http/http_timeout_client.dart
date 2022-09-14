import 'dart:io';

class HttpTimeoutClient {
  HttpTimeoutClient(this.client,
      { required this.connectionTimeout, required this.idleTimeout}) {
    client.connectionTimeout = Duration(milliseconds: connectionTimeout);
    client.idleTimeout = Duration(milliseconds: connectionTimeout);
    client.maxConnectionsPerHost = 3;
  }

  final HttpClient client;
  final int connectionTimeout;
  final int idleTimeout;

  final Duration timeout = const Duration(seconds: 10);
}
