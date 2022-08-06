import 'dart:collection';

abstract class Site {
  int? id;
  int? version;
  String? name;
  String? author;
  String? rating;
  String? details;
  String? type;
  String? icon;
  Headers? headers;
  Sections? sections;

  Site(this.id, this.version, this.name, this.author, this.rating, this.);

  User.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        email = json['email'];

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
  };
}

abstract class Headers {
// [key: string]: string
}

abstract class Sections {
// [key: string]: Section
  Section? home;
  Section? search;
}

abstract class Section {
  String? index;
  String? reuse;
  String? name;
  String? detail;
  // Rules? rules;
Map<String, Selector>? rules;
}

// abstract class Rules extends Map{
// // [key: string]: Selector
// Map<String, Selector>? selectors;
//   ChildrenNode? $children;
// }
abstract class Rules extends MapMixin<String, Selector> {

}
abstract class ChildrenNode extends Selector {
  bool? flat;
  // Rules? rules;
  Map<String, Selector>? rules;
}

abstract class Selector {
  String? selector;
  String? regex;
  String? capture;
  String? replacement;
}

abstract class Meta {
  List<Meta>? children;
  String? $children;
  Site? $site;
  Section? $section;
}
