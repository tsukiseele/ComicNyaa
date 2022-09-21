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

import 'package:comic_nyaa/library/http/http_timeout_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:http/retry.dart';

class NyaaClient extends http.BaseClient {
  NyaaClient({int connectionTimeout = 15000, int idleTimeout = 15000}) {
    final SecurityContext context = SecurityContext(withTrustedRoots: true);
    context.allowLegacyUnsafeRenegotiation = true;
    final client = HttpClient(context: context);
    // final client = HttpClient();
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
      return true;
    };
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
