import 'package:comic_nyaa/library/mio/core/mio.dart';
import 'package:comic_nyaa/model/typed_model.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class DetailsView extends StatefulWidget {
  const DetailsView({Key? key, required this.model}) : super(key: key);
  final title = '详情';
  final TypedModel model;

  @override
  State<StatefulWidget> createState() {
    return DetailViewState();
  }
}

class DetailViewState extends State<DetailsView> {
  final title = '';
  Map<String, dynamic>? children;
  VideoPlayerController? _controller;

  void getChildren() async {
    try {
      final model = widget.model;
      print('model.\$section: ${model.$section}');
      final dynamicResult = await Mio(model.$site).parseChildrenConcurrency(model.toJson(), model.$section!.rules!);

      print('data: $dynamicResult');
      // print('URL: ${dynamicResult.['sampleUrl'] ?? dynamicResult['largerUrl'] ?? dynamicResult['originUrl']}');
      print('UUUUUU: ${getUrl(dynamicResult)}');
      setState(() {
        children = dynamicResult; //TypedModel.fromJson(dynamicResult);
      });
      final url = getUrl(children);
      print('PLAY URL: $url}');
      _controller = VideoPlayerController.network(url)
        // 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4')
        ..initialize().then((_) {
          print('IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII');
          // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
          setState(() {});
        });
    } catch (e) {
      print('ERROR: ${e.toString()}');
    }
    // return data;;
  }

  String getUrl(Map<String, dynamic>? item) {
    if (item == null) return '';
    try {
      print('AAAAAAAAA: ${item}');
      final children = item['children'] != null ? item['children'][0] : null;
      if (children != null) {
        print('CCCCCCCCC: ${children['sampleUrl']}, : ${children['largerUrl']}');
        return children['sampleUrl'] ?? children['largerUrl'] ?? children['originUrl'];
      }
      print('BBBBBBBBBBBB: ${item['sampleUrl'] ?? item['largerUrl'] ?? item['originUrl']}');
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
                child: widget.model.type == 'image'
                    ? Image.network(getUrl(children))
                    : _controller?.value.isInitialized ?? false
                        ? AspectRatio(
                            aspectRatio: _controller?.value.aspectRatio ?? .75,
                            child: VideoPlayer(_controller!),
                          )
                        : Container(),
              ),
              // Image.network(getUrl(children)),
              // const Text('FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF'),
              ElevatedButton(
                  onPressed: () {
                    _controller?.value.isPlaying ?? false ? _controller?.pause() : _controller?.play();
                  },
                  child: const Text('播放')),
              Text(title)
            ])));
  }
}
