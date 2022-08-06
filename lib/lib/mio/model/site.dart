import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:comic_nyaa/lib/mio/model/site_.dart';

import 'base.dart';

class Site {
  String? name;
  int? id;
  int? version;
  String? author;
  String? rating;
  String? details;
  String? type;
  String? icon;
  Headers? headers;
  Sections? sections;

  Site(
      {this.name,
        this.id,
        this.version,
        this.author,
        this.rating,
        this.details,
        this.type,
        this.icon,
        this.headers,
        this.sections});

  Site.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    id = json['id'];
    version = json['version'];
    author = json['author'];
    rating = json['rating'];
    details = json['details'];
    type = json['type'];
    icon = json['icon'];
    headers =
    json['headers'] != null ? new Headers.fromJson(json['headers']) : null;
    sections = json['sections'] != null
        ? new Sections.fromJson(json['sections'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['id'] = this.id;
    data['version'] = this.version;
    data['author'] = this.author;
    data['rating'] = this.rating;
    data['details'] = this.details;
    data['type'] = this.type;
    data['icon'] = this.icon;
    if (this.headers != null) {
      data['headers'] = this.headers!.toJson();
    }
    if (this.sections != null) {
      data['sections'] = this.sections!.toJson();
    }
    return data;
  }
}

class Headers extends BaseMap<String, String> {
  Headers.fromJson(super.json) : super.fromJson();
}

class Sections extends BaseMap<String, Section> {
  Sections.fromJson(super.json) : super.fromJson();
}

class Section {
  String? index;
  String? name;
  String? details;
  Rules? rules;

  Section({this.index, this.name, this.details, this.rules});

  Section.fromJson(Map<String, dynamic> json) {
    index = json['index'];
    name = json['name'];
    details = json['details'];
    rules = json['rules'] != null ? Rules.fromJson(json['rules']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['index'] = index;
    data['name'] = name;
    data['details'] = details;
    if (rules != null) {
      data['rules'] = rules!.toJson();
    }
    return data;
  }
}

class Children {
  String? selector;
  String? capture;
  String? replacement;
  Rules? rules;

  Children({this.selector, this.capture, this.replacement, this.rules});

  Children.fromJson(Map<String, dynamic> json) {
    selector = json['selector'];
    capture = json['capture'];
    replacement = json['replacement'];
    rules = json['rules'] != null ? Rules.fromJson(json['rules']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['selector'] = selector;
    data['capture'] = capture;
    data['replacement'] = replacement;
    if (rules != null) {
      data['rules'] = rules!.toJson();
    }
    return data;
  }
}

class Rules extends BaseMap<String, Selector> {
  Rules.fromJson(super.json) : super.fromJson();
  // Rules.fromJson(Map<String, Selector> json) {
  //   addAll(json);
  // }
  // Map<String, dynamic> toJson() => this;
}

class Search {
  String? index;
  String? reuse;

  Search({this.index, this.reuse});

  Search.fromJson(Map<String, dynamic> json) {
    index = json['index'];
    reuse = json['reuse'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['index'] = this.index;
    data['reuse'] = this.reuse;
    return data;
  }
}