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
}

class Subscribe {
  Subscribe({required this.name, required this.url, this.updateTime});

  String name;
  String url;
  String? updateTime;
}
