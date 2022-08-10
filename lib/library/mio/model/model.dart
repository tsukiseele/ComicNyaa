import './site.dart';

abstract class Model<T> {

  String? type;
  List<T>? children;// 需要实现类序列化
  String? $children;
  Site? $site; // 不可序列化
  Section? $section; // 不可序列化

  Model({this.type, this.children, this.$children, this.$site, this.$section});

  Model.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    // children = json['children'];
    $children = json[r'$children'];
    $site = json[r'$site'];
    $section = json[r'$section'];
    // $site = json[r'$site'] != null ?  Site.fromJson(json[r'$site']) : null;
    // $section = json[r'$section'] != null ? Section.fromJson(json[r'$section']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    // data['children'] = children;
    data[r'$children'] = $children;
    data[r'$site'] = $site;
    data[r'$section'] = $section;
    // if ($site != null) {
    //   data[r'$site'] = $site!.toJson();
    // }
    // if ($section != null) {
    //   data[r'$section'] = $section!.toJson();
    // }
    return data;
  }
}
