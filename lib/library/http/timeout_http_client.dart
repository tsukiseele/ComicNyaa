import 'dart:io';

class TimeoutHttpClient {
  TimeoutHttpClient(this.client,
      { required this.connectionTimeout, required this.idleTimeout}) {
    client.connectionTimeout = Duration(milliseconds: connectionTimeout);
    client.idleTimeout = Duration(milliseconds: connectionTimeout);
  }

  final HttpClient client;
  final int connectionTimeout;
  final int idleTimeout;

  final Duration timeout = const Duration(seconds: 10);
}
