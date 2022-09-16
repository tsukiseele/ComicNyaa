import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart';

Future<String> readResponse(HttpClientResponse response) {
  final completer = Completer<String>();
  final contents = StringBuffer();
  response.transform(utf8.decoder).listen((data) {
    contents.write(data);
  }, onDone: () => completer.complete(contents.toString()));
  return completer.future;
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
void main() async {
  SecurityContext context = SecurityContext(withTrustedRoots: true);

  // SecureSocket socket = context.
  HttpClient client = HttpClient(context: context);
  client.findProxy = (url) {
    return HttpClient.findProxyFromEnvironment(
        url, environment: {"http_proxy": '127.0.0.1:7890', "https_proxy": '127.0.0.1:7890'});
  };
  // client.get('https://e-hentai.org/', port, path)
  HttpClientRequest request = await client.getUrl(Uri.parse('https://baidu.com/'));
  // request.headers.add('host', 'e-hentai.org');
  // request.headers.add('Cookie', 'igneous=ed27332b5; ipb_member_id=4249385; ipb_pass_hash=887e9708aaae76e7161526fd299cff64; sl=dm_1;');
  HttpClientResponse response = await request.close();
  final result = await readResponse(response);
  print(result);
  // """
  //       通过 Cloudflare 的 DNS over HTTPS 请求真实的 IP 地址。
  //       """
  // URLS = (
  //     "https://cloudflare-dns.com/dns-query",
  //     "https://1.0.0.1/dns-query",
  //     "https://1.1.1.1/dns-query",
  //     "https://[2606:4700:4700::1001]/dns-query",
  //     "https://[2606:4700:4700::1111]/dns-query",
  // )
  // params = {
  //   "ct": "application/dns-json",
  //   "name": hostname,
  //   "type": "A",
  //   "do": "false",
  //   "cd": "false",
  // }

}