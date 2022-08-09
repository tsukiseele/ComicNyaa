import './site.dart';

abstract class Model {
  List<Model>? children;
  String? $children;
  Site? $site;
  Section? $section;
  String? type;

  Model({this.type, this.children, this.$children, this.$site, this.$section});

  static formJson<T extends Model>(T type) {

  }
  Model.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    children = json['children'];
    $children = json[r'$children'];
    $site = json[r'$site'] != null ? Site.fromJson(json[r'$site']) : null;
    $section = json[r'$section'] != null ? Section.fromJson(json[r'$section']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    data['children'] = children;
    data[r'$children'] = $children;
    if ($site != null) {
      data[r'$site'] = $site!.toJson();
    }
    if ($section != null) {
      data[r'$section'] = $section!.toJson();
    }
    return data;
  }
}
