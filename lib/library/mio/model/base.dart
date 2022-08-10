import 'dart:collection';

isEmpty(Object? o) {
  return o == null || o == "";
}


class BaseMap<K, V> extends MapMixin<K, V> {
  Map<K, V> json = <K, V>{};

  @override
  V? operator [](Object? key) {
    return json[key];
  }

  @override
  void operator []=(K key, V value) {
    json[key] = value;
  }

  @override
  void clear() {
    json.clear();
  }

  @override
  // TODO: implement keys
  Iterable<K> get keys => json.keys;

  @override
  V? remove(Object? key) {
    return json.remove(key);
  }

  // BaseMap.fromJson(Map<String, dynamic> json) {
  //   final val = json.map((key, value) => MapEntry(key as K, value as V));
  //   addAll(val);
  // }

  BaseMap<String, dynamic> toJson() => this as BaseMap<String, dynamic>;
}

extension BoolParsing on String {
  bool parseBool() {
    if (toLowerCase() == 'true') {
      return true;
    } else if (toLowerCase() == 'false') {
      return false;
    }
    return false;
    // throw '"$this" can not be parsed to boolean.';
  }
}