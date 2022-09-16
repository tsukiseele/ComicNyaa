/*
 * Copyright (C) 2022. TsukiSeele
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

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
    data['children'] = children?.map((child) => child.toJson()).toList();
    data.addAll(super.toJson());
    return data;
  }
}
