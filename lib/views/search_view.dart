import 'package:comic_nyaa/views/pages/gallery_view.dart';
import 'package:flutter/material.dart';

import '../library/mio/model/site.dart';
///
/// The widget unused
class SearchView extends StatelessWidget {
  const SearchView({Key? key, required this.site, required this.keywords})
      : super(key: key);
  final Site site;
  final String keywords;

  @override
  Widget build(BuildContext context) {
    final view = GalleryView(site: site);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {

      view.controller.search?.call(keywords);
    });
    return Scaffold(
        appBar: AppBar(
          title: Text('搜索: $keywords'),
        ),
        body: view);
  }
}