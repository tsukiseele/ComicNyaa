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

import 'package:chewie/chewie.dart';
import 'package:comic_nyaa/library/mio/core/mio.dart';
import 'package:comic_nyaa/library/mio/model/data_origin.dart';
import 'package:comic_nyaa/models/typed_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:video_player/video_player.dart';

class VideoDetailView extends StatefulWidget {
  const VideoDetailView({Key? key, required this.model}) : super(key: key);
  final title = '视频';
  final TypedModel model;

  @override
  State<StatefulWidget> createState() {
    return VideoDetailViewState();
  }
}

class VideoDetailViewState extends State<VideoDetailView> {
  TypedModel? model;
  VideoPlayerController? _controller;
  ChewieController? _chewieController;
  late DataOrigin _origin;

  Future<void> play(String url) async {
    if (url == '') return;
    // 丢弃原始源
    await _controller?.dispose();
    _chewieController?.dispose();
    // 加载新URL
    _controller = VideoPlayerController.network(url);
    await _controller?.initialize();
    setState(() {
      _chewieController = ChewieController(
        videoPlayerController: _controller!,
        autoPlay: true,
        looping: true,
      );
    });
  }

  void _getChildren() async {
    // try {
    final parent = widget.model;
    _origin = parent.getOrigin();
    final dynamicResult = await Mio(_origin.site).parseAllChildren(parent.toJson());
    final model = TypedModel.fromJson(dynamicResult);
    // 加载视频
    await play(getUrl(model));

    setState(() {
      this.model = model;
    });
  }

  String getUrl(TypedModel? item) {
    if (item == null) return '';
    try {
      final children = item.children != null ? item.children![0] : null;
      if (children != null) {
        return children.originUrl ?? children.largerUrl ?? children.sampleUrl ?? '';
      }
      return item.originUrl ?? item.largerUrl ?? item.sampleUrl ?? '';
    } catch (e) {
      rethrow;
    }
  }

  @override
  void initState() {
    super.initState();
    _getChildren();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Container(
          alignment: Alignment.center,
            padding: const EdgeInsets.all(8.0),
            child:
              Center(
                child: Column(children: [_controller?.value.isInitialized ?? false
                    ? AspectRatio(
                        aspectRatio: _controller?.value.aspectRatio ?? 16 / 9,
                        child: Chewie(controller: _chewieController!))
                    : const Center(child: SpinKitWave(color: Colors.teal)),
                  Row(
                    children: [
                      Offstage(
                          offstage: model?.originUrl == null,
                          child: ElevatedButton(
                              onPressed: () {
                                play(model!.originUrl!);
                                // _controller?.value.isPlaying ?? false ? _controller?.pause() : _controller?.play();
                              },
                              child: const Text('高解析度'))),
                      Offstage(
                          offstage: model?.largerUrl == null,
                          child: ElevatedButton(
                              onPressed: () {
                                play(model!.largerUrl!);
                                // _controller?.value.isPlaying ?? false ? _controller?.pause() : _controller?.play();
                              },
                              child: const Text('中解析度'))),
                      Offstage(
                          offstage: model?.sampleUrl == null,
                          child: ElevatedButton(
                              onPressed: () {
                                play(model!.sampleUrl!);
                                // _controller?.value.isPlaying ?? false ? _controller?.pause() : _controller?.play();
                              },
                              child: const Text('低解析度'))),
                    ],
                  ),
                ]
              ),
              )));
  }

  @override
  void dispose() {
    _controller?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }
}
