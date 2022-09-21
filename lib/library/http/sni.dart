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


import 'dart:convert';

import 'package:collection/collection.dart';

import 'http.dart';

const hosts = [
  'exhentai.org',
  'e-hentai.org'
];

final ipCache = <String, String>{};

getIpFromGf( String host) async {
  final headers = <String, String>{};
  headers['Content-Type'] = 'application/json';
  final dnsResponse = await Http.client.post(Uri.parse('https://geekflare.com/api/geekflare-api/dnsrecord'), headers: headers, body: '{"url":"$host"}');
  final dns = Map<String, dynamic>.from(jsonDecode(dnsResponse.body));
  final targetIp = dns['data']['A'][0]['address'];
  return targetIp;
}

Future<Uri> getSniUri(Uri uri) async {
  final host = uri.host;

  String? ip = ipCache[host];
  if (ip == null) {
    ip = await getIpFromGf(host);
    ipCache[host] = ip!;
  }
  return uri = uri.replace(host: ip);
}

Future<String> parse(String url, {Map<String, String>? headers}) async {
  final uri = Uri.parse(url);
  final host = uri.host;
  final inSniList = hosts.firstWhereOrNull((h) => host.contains(h));
  if (inSniList != null) {
    headers?['Host'] = host;
    return (await getSniUri(uri)).toString();
  }
  return url;
}

