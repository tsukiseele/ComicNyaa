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
    final view = GalleryView(site: site, heroKey: '0');
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