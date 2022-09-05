import '../core/mio_loader.dart';
import 'data_origin.dart';

abstract class Model<T> {
  String? type;
  // List<String>? sources;
  List<T>? children; // 需要在子类实现序列化
  String? $children;
  DataOriginInfo? $origin;

  Model.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    $children = json[r'$children'];
    $origin = json[r'$origin'] != null
        ? DataOriginInfo.fromJson(json[r'$origin'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    data[r'$children'] = $children;
    if ($origin != null) data[r'$origin'] = $origin!.toJson();
    return data;
  }

  DataOrigin getOrigin() {
    final origin = $origin;
    if (origin == null || !origin.isAvaliable()) {
      throw Exception('Unavailable data origin!');
    }
    final site = MioLoader.getSiteByOrigin(origin)!;
    final section = site.sections![origin.sectionName]!;
    return DataOrigin(site, section);
  }
}
