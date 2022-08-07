import 'dart:collection';
import 'dart:math';

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
  //   print('STARTTTTTTTTTTTT:');
  //
  //   final val = json.map((key, value) => MapEntry(key as K, value as V));
  //   print('VALTYPE:' + val.runtimeType.toString());
  //
  //   addAll(val);
  //   print('XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX');
  // }

  BaseMap<String, dynamic> toJson() => this as BaseMap<String, dynamic>;
}