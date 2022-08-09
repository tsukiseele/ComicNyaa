import './base.dart';

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
    id = int.parse(json['id'].toString());
    version = int.parse(json['version'].toString());
    author = json['author'];
    rating = json['rating'];
    details = json['details'];
    type = json['type'];
    icon = json['icon'];
    headers = json['headers'] != null ? Headers.fromJson(json['headers']) : null;
    sections = json['sections'] != null ? Sections.fromJson(json['sections']) : null;
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
    return data;
  }
}

class Headers extends BaseMap<String, String> {
  // Headers.fromJson(super.json) : super.fromJson();

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

class Children {
  String? selector;
  String? capture;
  String? replacement;
  String? extend;
  Rules? rules;

  Children({this.selector, this.capture, this.replacement, this.extend, this.rules});

  Children.fromJson(Map<String, dynamic> json) {
    selector = json['selector'];
    capture = json['capture'];
    replacement = json['replacement'];
    extend = json['extend'];
    rules = json['rules'] != null ? Rules.fromJson(json['rules']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['selector'] = selector;
    data['capture'] = capture;
    data['replacement'] = replacement;
    data['extend'] = extend;
    if (rules != null) {
      data['rules'] = rules!.toJson();
    }
    return data;
  }
}

class Selector {
  String? regex;
  String? selector;
  String? capture;
  String? replacement;
  bool? flat; // $children only
  bool? extend; // $children only
  Rules? rules; // $children only

  Selector({this.regex, this.selector, this.capture, this.replacement, this.flat, this.extend, this.rules});

  Selector.fromJson(Map<String, dynamic> json) {
    regex = json['regex'];
    selector = json['selector'];
    capture = json['capture'];
    replacement = json['replacement'];
    flat = bool.fromEnvironment(json['flat'].toString());
    extend = bool.fromEnvironment(json['extend'].toString());
    rules = json['rules'] != null ? Rules.fromJson(json['rules']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['regex'] = regex;
    data['selector'] = selector;
    data['capture'] = capture;
    data['replacement'] = replacement;
    data['flat'] = flat;
    data['extend'] = extend;
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

class Search {
  String? index;
  String? reuse;

  Search({this.index, this.reuse});

  Search.fromJson(Map<String, dynamic> json) {
    index = json['index'];
    reuse = json['reuse'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['index'] = index;
    data['reuse'] = reuse;
    return data;
  }
}

