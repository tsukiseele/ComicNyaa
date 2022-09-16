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

import 'package:collection/collection.dart';
import 'package:comic_nyaa/utils/extensions.dart';
import 'package:comic_nyaa/utils/uri_extensions.dart';

import '../app/config.dart';
import '../library/mio/core/site_manager.dart';
import '../library/http/http.dart';

class SubscribeProvider {
  SubscribeProvider._();

  static final SubscribeProvider _instance = SubscribeProvider._();

  factory SubscribeProvider() {
    return _instance;
  }

  final _subscribes = [
    Subscribe(name: 'Default', url: 'https://hlo.li/static/rules.zip')
  ];

  List<Subscribe> get subscribes {
    return _subscribes;
  }


  Future<void> addSubscribe(Subscribe subscribe) async {
    Subscribe? existed = _subscribes.firstWhereIndexedOrNull((i, item) {
      if (item.equals(subscribe)) {
        subscribes[i] = subscribe;
        return true;
      }
      return false;
    });
    if (existed == null) _subscribes.add(subscribe);
    return await updateSubscribe(subscribe);
  }

  Future<void> removeSubscribe(Subscribe subscribe) async {
    _subscribes.removeWhere((item) => item.url == subscribe.url);
  }

  Future<void> removeSubscribeFromUrl(String url) async {
    removeSubscribe(Subscribe(name: 'unnamed', url: url));
  }

  Future<void> updateSubscribe(Subscribe subscribe) async {
    final url = subscribe.url;
    final dir = await Config.ruleDir;
    final savePath = dir.join(Uri.parse(url).filename).path;
    await Http.downloadFile(url, savePath);
    await SiteManager.loadFromDirectory(dir);
  }

  Future<void> updateSubscribeFromUrl(String url) async {
    await updateSubscribe(Subscribe(name: 'unnamed', url: url));
  }

  Future<void> updateAllSubscribe() async {
     await Future.wait(_subscribes.map((e) => updateSubscribe(e)));
  }
}

class Subscribe {
  Subscribe({required this.name, required this.url, this.updateTime});

  String name;
  String url;
  String? updateTime;

  bool equals(Subscribe s) {
    if (name == s.name && url == s.url) {
      return true;
    }
    return false;
  }
}
