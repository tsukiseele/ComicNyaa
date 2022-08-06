import 'dart:collection';

class BaseMap<K, V> extends MapMixin<K, V> {
  Map<K, V> json = Map.identity();

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

  BaseMap.fromJson(Map<K, V> json) {
    addAll(json);
  }
  BaseMap<String, dynamic> toJson() => this as BaseMap<String, dynamic>;
}