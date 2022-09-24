import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<String> readResponseAsText(HttpClientResponse response) {
  final completer = Completer<String>();
  final contents = StringBuffer();
  response.transform(utf8.decoder).listen((data) {
    contents.write(data);
  }, onDone: () => completer.complete(contents.toString()));
  return completer.future;
}

getIpFromCf(HttpClient client, String host) async {
  final dnsReq = await client.getUrl(Uri.parse('https://1.1.1.1/dns-query?name=$host'));
  dnsReq.headers.add('Accept', 'application/dns-json');
  final dnsData = await readResponseAsText(await dnsReq.close());
  final dns = Map<String, dynamic>.from(jsonDecode(dnsData));
  final targetIp = dns['Answer'][0]['data'];
  return targetIp;
}

getIpFromGf(HttpClient client, String host) async {
  final dnsReq = await client.postUrl(Uri.parse('https://geekflare.com/api/geekflare-api/dnsrecord'));
  dnsReq.headers.add('Content-Type', 'application/json');
  dnsReq.write('{"url":"$host"}');
  final dnsData = await readResponseAsText(await dnsReq.close());
  final dns = Map<String, dynamic>.from(jsonDecode(dnsData));
  final targetIp = dns['data']['A'][0]['address'];
  return targetIp;
}

getIpFromNc(HttpClient client, String host) async {
  final dnsReq = await client.getUrl(Uri.parse('https://networkcalc.com/api/dns/lookup/$host'));
  dnsReq.headers.add('Content-Type', 'application/json');
  final dnsData = await readResponseAsText(await dnsReq.close());
  final dns = Map<String, dynamic>.from(jsonDecode(dnsData));
  final targetIp = dns['records']['A'][0]['address'];
  return targetIp;
}

void main() async {
  const url = 'https://exhentai.org/g/2334437/2f90c26bb5/';
  final headers = {
    'Cookie': 'igneous=ed27332b5; ipb_member_id=4249385; ipb_pass_hash=887e9708aaae76e7161526fd299cff64; sl=dm_1;'
  };
  final response = await send(url, headers: headers);

  final result = await readResponseAsText(response);
  print(result);
}

Future<HttpClientResponse> send(String url, {Map<String, String>? headers}) async {
  SecurityContext context = SecurityContext(withTrustedRoots: true);
  HttpClient client = HttpClient(context: context);
  client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  // client.findProxy = (url) =>
  //     HttpClient.findProxyFromEnvironment(url, environment: {"http_proxy": '127.0.0.1:7890', "https_proxy": '127.0.0.1:7890'});
  client.connectionTimeout = const Duration(seconds: 8);
  //
  Uri uri = Uri.parse(url);
  final targetHost = uri.host;
  final targetIp = await getIpFromGf(client, targetHost);
  uri = uri.replace(host: targetIp);
  //
  final request = await client.getUrl(uri);
  request.headers.add('Host', targetHost);
  if (headers != null) {
    headers.forEach((name, value) => request.headers.add(name, value));
  }
  final response = await request.close();
  return response;
}
