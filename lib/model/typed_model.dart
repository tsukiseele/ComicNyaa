import 'package:comic_nyaa/library/mio/model/model.dart';

enum TYPE {
  image,
  video,
  comic
}
class TypedModel extends Model {
  String? coverUrl;
  String? title;

  TypedModel({this.coverUrl, this.title});

  TypedModel.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    coverUrl = json['coverUrl'];
    title = json['title'];
    // children = json['children'] != null ? json['children'].map((item) => TypedModel.fromJson(item)) : null;
  }

  @override
  String toString() {
    return 'TypedModel{coverUrl: $coverUrl, title: $title}';
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['coverUrl'] = coverUrl;
    data['title'] = title;

    // data[r'$children'] = $children;
    data.addAll(super.toJson());
    return data;
  }
}
