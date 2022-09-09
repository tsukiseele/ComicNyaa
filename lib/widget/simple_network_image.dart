import 'package:comic_nyaa/utils/uri_extensions.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SimpleNetworkImage extends StatefulWidget {
  const SimpleNetworkImage(this.url,
      {Key? key,
      this.width,
      this.height,
      this.duration = const Duration(milliseconds: 500),
      this.headers,
      this.fit = BoxFit.contain,
      this.clearMemoryCacheIfFailed = true,
      this.placeholder,
      this.error})
      : super(key: key);
  final String url;
  final double? width;
  final double? height;
  final Duration duration;
  final Map<String, String>? headers;
  final BoxFit fit;
  final bool clearMemoryCacheIfFailed;
  final Widget? error;
  final Widget? placeholder;

  @override
  State<StatefulWidget> createState() {
    return _SimpleNetworkImageState();
  }
}

class _SimpleNetworkImageState extends State<SimpleNetworkImage>
    with TickerProviderStateMixin<SimpleNetworkImage> {
  AnimationController? animationController;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(duration: widget.duration, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return ExtendedImage.network(
      widget.url.asUrl,
      width: widget.width,
      height: widget.height,
      headers: widget.headers,
      fit: widget.fit,
      opacity: animationController,
      clearMemoryCacheIfFailed: widget.clearMemoryCacheIfFailed,
      loadStateChanged: (state) {
        switch (state.extendedImageLoadState) {
          case LoadState.loading:
            animationController?.reset();
            return widget.placeholder ??
                Center(
                    child: Shimmer.fromColors(
                  baseColor: const Color.fromRGBO(240, 240, 240, 1),
                  highlightColor: Colors.white,
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.white),
                  ),
                ));
          case LoadState.failed:
            animationController?.forward();
            return widget.error;
          case LoadState.completed:
            animationController?.forward();
            return null;
        }
      },
    );
  }

  @override
  void dispose() {
    animationController?.dispose();
    super.dispose();
  }
}
