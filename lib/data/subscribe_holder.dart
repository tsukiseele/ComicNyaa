import 'package:collection/collection.dart';
import 'package:comic_nyaa/utils/uri_extensions.dart';

import '../app/global.dart';
import '../library/mio/core/mio_loader.dart';
import '../utils/http.dart';

class SubscribeHolder {
  SubscribeHolder._();

  static final SubscribeHolder _instance = SubscribeHolder._();

  factory SubscribeHolder() {
    return _instance;
  }

  final _subscribes = [
    Subscribe(name: 'Default', url: 'https://hlo.li/static/rules.zip')
  ];

  List<Subscribe> get subscribes {
    return _subscribes;
  }

  addSubscribe(Subscribe subscribe) {
    _subscribes.((i, item){ if (item.equals(subscribe)) {
    subscribes[i] = subscribe;
    }});
    return ;
  }

  Future<void> updateSubscribe(Subscribe subscribe) async {

    final url = subscribe.url;
    final dir = await Config.ruleDir;
    final savePath = dir.join(Uri.parse(url).filename).path;
    await Http.client().download(url, savePath);
    await RuleLoader.loadFormDirectory(dir);
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
