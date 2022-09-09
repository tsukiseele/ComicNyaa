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
