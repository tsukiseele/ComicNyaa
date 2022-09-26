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

import 'site.dart';

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
