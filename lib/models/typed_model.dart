import 'package:comic_nyaa/library/mio/model/data_model.dart';

class TypedModel extends DataModel<TypedModel> {
  String? title;
  String? tags;
  String? coverUrl;
  String? originUrl;
  String? largerUrl;
  String? sampleUrl;

  TypedModel.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    title = json['title'];
    tags = json['tags'];
    coverUrl = json['coverUrl'];
    originUrl = json['originUrl'];
    largerUrl = json['largerUrl'];
    sampleUrl = json['sampleUrl'];
    if (json['children'] != null) {
      children = json['children']?.map((item) => TypedModel.fromJson(item));
    }
  }

  @override
  String toString() {
    return 'TypedModel{title: $title, tags: $tags, coverUrl: $coverUrl, originUrl: $originUrl, largerUrl: $largerUrl, sampleUrl: $sampleUrl, }';
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['title'] = title;
    data['tags'] = tags;
    data['coverUrl'] = coverUrl;
    data['originUrl'] = originUrl;
    data['largerUrl'] = largerUrl;
    data['sampleUrl'] = sampleUrl;
    data['children'] = children?.map((child) => child.toJson()).toList();
    data.addAll(super.toJson());
    return data;
  }
}
