import 'package:comic_nyaa/library/mio/model/model.dart';

class TypedModel extends Model<TypedModel> {
  String? title;
  String? tags;
  String? coverUrl;
  String? originUrl;
  String? largerUrl;
  String? sampleUrl;

  TypedModel(this.title, this.tags, this.coverUrl, this.originUrl, this.largerUrl, this.sampleUrl);

  TypedModel.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    title = json['title'];
    tags = json['tags'];
    coverUrl = json['coverUrl'];
    originUrl = json['originUrl'];
    largerUrl = json['largerUrl'];
    sampleUrl = json['sampleUrl'];
    if (json['children'] != null) {

      var children = <TypedModel>[];
      // print('CHILDREN: ${json['children'].runtimeType.toString()}, LENGTH: ${json['children'].length}');
      // children = json['children']?.map((item) => TypedModel.fromJson(item));
      json['children'].forEach((item) {
        // print('ITEM: $item');
        children.add(TypedModel.fromJson(item));
      });
      this.children = children;
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
    data['children'] = children?.map((e) => e.toJson());

    // data[r'$children'] = $children;
    data.addAll(super.toJson());
    return data;
  }
}
