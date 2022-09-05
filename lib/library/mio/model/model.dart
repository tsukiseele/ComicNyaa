import '../core/mio_loader.dart';
import 'data_origin.dart';

abstract class Model<T> {

  String? type;
  // List<String>? sources;
  List<T>? children;// 需要在子类序列化
  String? $children;
  // Site? $site; // 不可序列化
  // Section? $section; // 不可序列化
  DataOriginInfo? $origin;

  Model.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    // children = json['children'];
    $children = json[r'$children'];
    // $site = json[r'$site'];
    // $section = json[r'$section'];
    $origin = json[r'$origin'] != null ?  DataOriginInfo.fromJson(json[r'$origin']) : null;

    // $site = json[r'$site'] != null ?  Site.fromJson(json[r'$site']) : null;
    // $section = json[r'$section'] != null ? Section.fromJson(json[r'$section']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    // data['children'] = children;
    data[r'$children'] = $children;
    if ($origin != null) data[r'$origin'] = $origin!.toJson();
    // data[r'$site'] = $site;
    // data[r'$section'] = $section;
    // if ($site != null) {
    //   data[r'$site'] = $site!.toJson();
    // }
    // if ($section != null) {
    //   data[r'$section'] = $section!.toJson();
    // }
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
