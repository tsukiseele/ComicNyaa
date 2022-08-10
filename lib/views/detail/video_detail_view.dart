import 'package:chewie/chewie.dart';
import 'package:comic_nyaa/library/mio/core/mio.dart';
import 'package:comic_nyaa/model/typed_model.dart';
import 'package:flutter/material.dart';
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
  final title = '';

  // Map<String, dynamic>? children;
  TypedModel? model;
  VideoPlayerController? _controller;
  ChewieController? _chewieController;

  Future<void> play(String url) async {
    if (url == '') return;
    print('PLAY URL: $url}');
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

  void getChildren() async {
    // try {
    final parent = widget.model;
    print('model.\$section: ${parent.$section}');
    final dynamicResult = await Mio(parent.$site).parseChildrenConcurrency(parent.toJson(), parent.$section!.rules!);
    final model = TypedModel.fromJson(dynamicResult);

    // 加载视频
    await play(getUrl(model));

    setState(() {
      this.model = model;
    });
  }

  // String getUrl(Map<String, dynamic>? item) {
  String getUrl(TypedModel? item) {
    if (item == null) return '';
    try {
      final children = item.children != null ? item.children![0] : null;
      if (children != null) {
        return children.originUrl ?? children.largerUrl ?? children.sampleUrl ?? '';
      }
      return item.originUrl ?? item.largerUrl ?? item.sampleUrl ?? '';
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
                child: widget.model.type == 'image'
                    ? Image.network(getUrl(model))
                    : _controller?.value.isInitialized ?? false
                        ? AspectRatio(
                            aspectRatio: _controller?.value.aspectRatio ?? 16/9,
                            // child: VideoPlayer(_controller!),
                            child: Chewie(controller: _chewieController!))
                        : Container(),
              ),
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
            ])));
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _controller?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }
}
