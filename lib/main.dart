import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:comic_nyaa/app/global.dart';
import 'package:comic_nyaa/views/detail/comic_detail_view.dart';
import 'package:comic_nyaa/views/detail/image_detail_view.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';

import 'package:comic_nyaa/library/mio/model/site.dart';
import 'package:comic_nyaa/library/mio/core/mio.dart';
import 'package:comic_nyaa/models/typed_model.dart';
import 'package:comic_nyaa/views/detail/video_detail_view.dart';

import 'comic_nyaa.dart';
import 'models/typed_model.dart';

void main() async {
  runApp(const ComicNyaa());
}

class ComicNyaa extends StatelessWidget {
  const ComicNyaa({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ComicNyaa',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: const MainView(title: 'Home'),
    );
  }
}