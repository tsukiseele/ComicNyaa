import '../core/site_manager.dart';
import 'data_origin.dart';

/// 抓取数据模型
/// 子类必须实现 toJson() 和 fromJson() 完成序列化
///
class DataModel<T> {
  String? type;
  // List<String>? sources;
  List<T>? children; // 需要在子类实现序列化
  String? $children;
  DataOriginInfo? $origin;

  DataModel.fromJson(Map<String, dynamic> json) {
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
    final site = SiteManager.getSiteByOriginInfo(origin)!;
    final section = site.sections![origin.sectionName]!;
    return DataOrigin(site, section);
  }
}
