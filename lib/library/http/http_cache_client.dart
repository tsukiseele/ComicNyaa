import 'package:http/http.dart' as http;

class HttpCacheClient extends http.BaseClient {
  final http.Client _inner;

  HttpCacheClient(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _inner.send(request);
  }
}
