extension UriExtension on Uri {

   String filename() {
    // final match = RegExp(r'[\s\S^\/]*\/([\s\S^\/].*?\.\w+)(\?[\s\S^\/]*)?$').allMatches(url);
    // if (match.isNotEmpty && match.first.groupCount > 0) {
    //   final filename = match.first.group(1);
    //   print('MATCH: $filename');
    //   return filename!;
    // }
    // throw Exception('无法从URL中解析文件名：$url');
    return toString().split("/").last.split('?').first;
  }
}