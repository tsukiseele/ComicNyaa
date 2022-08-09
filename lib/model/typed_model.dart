import 'package:comic_nyaa/library/mio/model/model.dart';

class TypedModel extends Model {
  String? coverUrl;
  String? title;

  TypedModel({this.coverUrl, this.title});

  TypedModel.fromJson(Map<String, dynamic> json) {
    coverUrl = json['coverUrl'];
    title = json['title'];
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
    data.addAll(super.toJson());
    return data;
  }
}