abstract class site {
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
Rules rules;
}

abstract class Rules {
// [key: string]: Selector
$children: ChildrenNode
}

interface ChildrenNode extends Selector {
flat?: boolean,
rules: Rules
}

interface Selector {
selector: string
regex: string,
capture?: string
replacement?: string
}

interface Meta {
children?: Meta[]
$children?: string
$site?: Site
$section?: Section
}
