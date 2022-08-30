import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class NyaaTags extends StatefulWidget {
  const NyaaTags({
    Key? key, required this.builder,
  }) : super(key: key);
  final IndexedWidgetBuilder builder;

  @override
  State<StatefulWidget> createState() {
    return _NyaaTagsState();
  }
}

class _NyaaTagsState extends State<NyaaTags>
    with TickerProviderStateMixin<NyaaTags> {
  AnimationController? animationController;

  @override
  void initState() {
    super.initState();
    animationController =
        AnimationController(duration: widget.duration, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(children: widget.builder.);
  }

  @override
  void dispose() {
    super.dispose();
    animationController?.dispose();
  }
}
