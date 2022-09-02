import 'package:comic_nyaa/models/typed_model.dart';

import '../app/preference.dart';
/// Emulation of Java Enum class.
///
/// Example:
///
/// class Meter<int> extends Enum<int> {
///
///   const Meter(int val) : super (val);
///
///   static const Meter HIGH = const Meter(100);
///   static const Meter MIDDLE = const Meter(50);
///   static const Meter LOW = const Meter(10);
/// }
///
/// and usage:
///
/// assert (Meter.HIGH, 100);
/// assert (Meter.HIGH is Meter);
abstract class Enum<T> {
  final T _value;
  const Enum(this._value);
  T get value => _value;
}

extension TypedModelEx on TypedModel {
  String getUrl(DownloadResourceLevel downloadResourceLevel) {
    String? url;
    switch (downloadResourceLevel) {
      case DownloadResourceLevel.low:
        url = sampleUrl ?? largerUrl ?? originUrl;
        break;
      case DownloadResourceLevel.medium:
        url = largerUrl ?? originUrl ?? sampleUrl;
        break;
      case DownloadResourceLevel.high:
        url = originUrl ?? largerUrl ?? sampleUrl;
        break;
    }
    if (url == null || url.trim().isEmpty) {
      return '';
    }
    return url;
  }
}
