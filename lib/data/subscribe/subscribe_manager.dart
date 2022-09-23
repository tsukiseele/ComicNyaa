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
import 'package:comic_nyaa/utils/extensions.dart';
import 'package:comic_nyaa/utils/uri_extensions.dart';
import '../../app/config.dart';
import '../../library/http/http.dart';
import '../../library/mio/core/site_manager.dart';
import '../subscribe_provider.dart';

class SubscribeManager {
  SubscribeManager._(this._provider);

  static SubscribeManager? _instance;

  static Future<SubscribeManager> get instance async {
    final provider = await SubscribeProvider().open();
    return _instance ??= SubscribeManager._(provider);
  }

  final SubscribeProvider _provider;

  Future<List<Subscribe>> get subscribes async {
    return await _provider.getSubscribes();
  }

  Future<bool> addSubscribe(Subscribe subscribe) async {
    final list = await subscribes;
    Subscribe? existed = list.firstWhereIndexedOrNull((i, item) {
      if (item.url == subscribe.url) {
        // list[i] = subscribe;
        return true;
      }
      return false;
    });
    if (existed == null) {
      subscribe.id = await _provider.insert(subscribe);
    } // return await updateSubscribe(subscribe);
    return true;
  }

  Future<void> removeSubscribe(Subscribe subscribe) async {
    final list = await subscribes;
    list.removeWhere((item) => item.url == subscribe.url);
  }

  Future<void> removeSubscribeFromUrl(String url) async {
    removeSubscribe(Subscribe(name: 'unnamed', url: url));
  }

  Future<bool> updateSubscribe(Subscribe subscribe) async {
    final url = subscribe.url;
    if (url == null) return false;
    final dir = await AppConfig.ruleDir;
    final path = await getRulePath(url);
    await Http.downloadFile(url, path);
    await SiteManager.loadFromDirectory(dir);
    return true;
  }

  Future<void> updateSubscribeFromUrl(String url) async {
    await updateSubscribe(Subscribe(name: 'unnamed', url: url));
  }

  Future<void> updateAllSubscribe() async {
    final list = await subscribes;
    await Future.wait(list.map((e) => updateSubscribe(e)));
  }

  Future<void> checkAndUpdateAllSubscribe() async {
    final list = await subscribes;
    await Future.wait(list.map((e) => _checkUpdate(e)));
  }

  Future<bool> _checkUpdate(Subscribe subscribe) async {
    final url = subscribe.url;
    if (url == null) return false;

    final versionUrl = '${url.substring(url.lastIndexOf('.'))}version';
    final response = await Http.client.get(Uri.parse(versionUrl));
    final json = jsonDecode(response.body);
    final version = json['version'];

    if (subscribe.version == null || subscribe.version! < version) {
      if (await updateSubscribe(subscribe)) {
        subscribe.version = version;
        _provider.update(subscribe);
        return true;
      }
    }
    return false;
  }

  Future<String> getRulePath(String url) async {
    final dir = await AppConfig.ruleDir;
    final path = dir.join(Uri.parse(url).filename);
    return path;
  }
}
