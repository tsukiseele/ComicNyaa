import 'package:comic_nyaa/lib/mio/model/site.dart';

abstract class Meta {
  List<Meta>? children;
  String? $children;
  Site? $site;
  Section? $section;

  Meta({this.children, this.$children, this.$site, this.$section});

  Meta.fromJson(Map<String, dynamic> json) {
    children = json['children'];
    $children = json[r'$children'];
    $site = json[r'$site'] != null ? Site.fromJson(json[r'$site']) : null;
    $section = json[r'$section'] != null ? Section.fromJson(json[r'$section']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
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

class MImage extends Meta {
  String? coverUrl;
  String? title;

  MImage({this.coverUrl, this.title});

  MImage.fromJson(Map<String, dynamic> json) {
    coverUrl = json['coverUrl'];
    title = json['title'];
  }

  @override
  String toString() {
    return 'MImage{coverUrl: $coverUrl, title: $title}';
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['coverUrl'] = coverUrl;
    data['title'] = title;
    data.addAll(super.toJson());
    return data;
  }
}