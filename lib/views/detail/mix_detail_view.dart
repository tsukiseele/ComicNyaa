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
import 'package:video_player/video_player.dart';

class MixDetailView extends StatefulWidget {
  const MixDetailView({Key? key, required this.model}) : super(key: key);
  final title = '混合视图';
  final TypedModel model;

  @override
  State<StatefulWidget> createState() {
    return MixDetailViewState();
  }
}

class MixDetailViewState extends State<MixDetailView> {
  Map<String, dynamic>? children;
  VideoPlayerController? _controller;
  ChewieController? _chewieController;
  late DataOrigin _origin;

  void getChildren() async {
    try {
      final model = widget.model;
      _origin = model.getOrigin();
      final dynamicResult = await Mio(_origin.site).parseAllChildren(model.toJson());

      print('data: $dynamicResult');
      // print('URL: ${getUrl(dynamicResult)}');
      setState(() {
        children = dynamicResult; //TypedModel.fromJson(dynamicResult);
      });
      // 加载视频
      final url = getUrl(children);
      print('PLAY URL: $url}');
      _controller = VideoPlayerController.network(url);
      await _controller?.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _controller!,
        autoPlay: true,
        looping: true,
      );
      // final playerWidget = Chewie(
      //   controller: chewieController,
      // );
      // 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4'
      // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
      setState(() {});
    } catch (e) {
      print('ERROR: ${e.toString()}');
    }
    // return data;;
  }

  String getUrl(Map<String, dynamic>? item) {
    if (item == null) return '';
    try {
      final children = item['children'] != null ? item['children'][0] : null;
      if (children != null) {
        return children['sampleUrl'] ?? children['largerUrl'] ?? children['originUrl'];
      }
      return item['sampleUrl'] ?? item['largerUrl'] ?? item['originUrl'] ?? '';
    } catch (e) {
      print('ERROR: $e');
    }
    return '';
  }

  @override
  void initState() {
    getChildren();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Container(
            padding: const EdgeInsets.all(8.0),
            child: Column(children: [
              Center(
                child: widget.model.$type == 'image'
                    ? Image.network(getUrl(children))
                    : _controller?.value.isInitialized ?? false
                    ? AspectRatio(
                    aspectRatio: _controller?.value.aspectRatio ?? .75,
                    // child: VideoPlayer(_controller!),
                    child: Chewie(controller: _chewieController!))
                    : Container(),
              ),
              Offstage(
                offstage: widget.model.$type == 'video',
                child: Row(
                  children: [
                    Offstage(
                        offstage: children?['originUrl'] != null,
                        child: ElevatedButton(
                            onPressed: () {
                              // _controller?.value.isPlaying ?? false ? _controller?.pause() : _controller?.play();
                            },
                            child: const Text('高解析度'))),
                    Offstage(
                        offstage: children?['largerUrl'] != null,
                        child: ElevatedButton(
                            onPressed: () {
                              // _controller?.value.isPlaying ?? false ? _controller?.pause() : _controller?.play();
                            },
                            child: const Text('中解析度'))),
                    Offstage(
                        offstage: children?['sampleUrl'] != null,
                        child: ElevatedButton(
                            onPressed: () {
                              // _controller?.value.isPlaying ?? false ? _controller?.pause() : _controller?.play();
                            },
                            child: const Text('低解析度'))),
                  ],
                ),
              )
            ])));
  }
}
