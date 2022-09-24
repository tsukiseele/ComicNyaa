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

import '../utils/base_map.dart';

class DomainFronting {
  String? country;

  DomainFronting.fromJson(Map<String, dynamic> json) {
    country = json['country'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['country'] = country;
    return data;
  }
}

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
  DomainFronting? domainFronting;

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
    id = int.parse(json['id'].toString());
    version = int.parse(json['version'].toString());
    author = json['author'];
    rating = json['rating'];
    details = json['details'];
    type = json['type'];
    icon = json['icon'];
    headers = json['headers'] != null ? Headers.fromJson(json['headers']) : null;
    sections = json['sections'] != null ? Sections.fromJson(json['sections']) : null;
    domainFronting = json['domainFronting'] != null ? DomainFronting.fromJson(json['domainFronting']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['id'] = id;
    data['version'] = version;
    data['author'] = author;
    data['rating'] = rating;
    data['details'] = details;
    data['type'] = type;
    data['icon'] = icon;
    if (headers != null) {
      data['headers'] = headers!.toJson();
    }
    if (sections != null) {
      data['sections'] = sections!.toJson();
    }
    if (domainFronting != null) {
      data['domainFronting'] = domainFronting!.toJson();
    }
    return data;
  }

  void includeSection() {
    sections?.forEach((key, section) {
      if (section.reuse != null) {
        section.rules = sections?['${section.reuse}']?.rules;
      }
    });
  }
}

class Headers extends BaseMap<String, String> {
  Headers.fromJson(Map<String, dynamic> json) {
    addAll(json.map((key, value) => MapEntry(key, value)));
  }
}

class Sections extends BaseMap<String, Section> {
  Sections.fromJson(Map<String, dynamic> json) {
    addAll(json.map((key, value) => MapEntry(key, Section.fromJson(value))));
  }
}

class Section {
  String? index;
  String? name;
  String? details;
  String? reuse;
  Rules? rules;

  Section({this.index, this.name, this.reuse, this.details, this.rules});

  Section.fromJson(Map<String, dynamic> json) {
    index = json['index'];
    name = json['name'];
    reuse = json['reuse'];
    details = json['details'];
    rules = json['rules'] != null ? Rules.fromJson(json['rules']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['index'] = index;
    data['name'] = name;
    data['reuse'] = reuse;
    data['details'] = details;
    if (rules != null) {
      data['rules'] = rules!.toJson();
    }
    return data;
  }
}

class Rules extends BaseMap<String, Selector> {
  Rules.fromJson(Map<String, dynamic> json) {
    addAll(json.map((key, value) => MapEntry(key, Selector.fromJson(value))));
  }
}

class Selector {
  String? regex;
  String? selector;
  String? capture;
  String? replacement;
  bool? merge;
  bool? flat; // $children only
  bool? inherit; // $children only
  Rules? rules; // $children only
  Rules? parent; // $children only

  Selector({this.regex, this.selector, this.capture, this.replacement, this.flat, this.inherit, this.rules});

  Selector.fromJson(Map<String, dynamic> json) {
    regex = json['regex'];
    selector = json['selector'];
    capture = json['capture'];
    replacement = json['replacement'];
    merge = json['merge']?.toString().parseBool();
    flat = json['flat']?.toString().parseBool();
    inherit = json['extended']?.toString().parseBool();
    rules = json['rules'] != null ? Rules.fromJson(json['rules']) : null;
    parent = json['parent'] != null ? Rules.fromJson(json['parent']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['regex'] = regex;
    data['selector'] = selector;
    data['capture'] = capture;
    data['replacement'] = replacement;
    data['merge'] = merge;
    data['flat'] = flat;
    data['extended'] = inherit;
    if (rules != null) {
      data['rules'] = rules!.toJson();
    }
    if (parent != null) {
      data['parent'] = parent!.toJson();
    }
    return data;
  }
}


