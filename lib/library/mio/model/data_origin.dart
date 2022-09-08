import 'package:comic_nyaa/library/mio/model/site.dart';

class DataOrigin {
  Site site;
  Section section;

  DataOrigin(this.site, this.section) {
    if (section.reuse != null) {
      section.rules = site.sections?['${section.reuse}']?.rules;
    }
  }

  Section getChildSectionByDepth(int depth) {
    Section childSection = section;
    for (int i = depth; i > 0; i--) {
      Rules? childRules = section.rules?[r'$children']?.rules;
      childSection = Section(rules: childRules);
    }
    return childSection;
  }
}

class DataOriginInfo {
  int? siteId;
  String? sectionName;
  int? depth;

  DataOriginInfo(this.siteId, this.sectionName, {this.depth = 0});

  DataOriginInfo.fromJson(Map<String, dynamic> json) {
    siteId = json['siteId'];
    sectionName = json['sectionName'];
    depth = int.parse(json['depth'].toString());
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['siteId'] = siteId;
    data['sectionName'] = sectionName;
    data['depth'] = depth;
    return data;
  }

  bool isAvaliable() {
    return siteId != null && sectionName != null && sectionName!.isNotEmpty;
  }
}
