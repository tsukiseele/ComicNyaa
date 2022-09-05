import 'package:comic_nyaa/library/mio/model/site.dart';

class DataOriginInfo {
  int? siteId;
  String? sectionName;

  DataOriginInfo(this.siteId, this.sectionName);

  DataOriginInfo.fromJson(Map<String, dynamic> json) {
    siteId = json['siteId'];
    sectionName = json['sectionName'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['siteId'] = siteId;
    data['sectionName'] = sectionName;
    return data;
  }

  bool isAvaliable() {
    return siteId != null && sectionName != null && sectionName!.isNotEmpty;
  }
}

class DataOrigin {
  Site site;
  Section section;

  DataOrigin(this.site, this.section);
}

