import 'package:flutter/material.dart';

class NyaaTags extends StatefulWidget {
  const NyaaTags({
    Key? key, required this.builder, required this.itemCount,
  }) : super(key: key);
  final IndexedWidgetBuilder builder;
  final int itemCount;

  @override
  State<StatefulWidget> createState() {
    return _NyaaTagsState();
  }
}

class _NyaaTagsState extends State<NyaaTags>
    with TickerProviderStateMixin<NyaaTags> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 1,
      runSpacing: 1,
      children: List.generate(
      widget.itemCount,
          (index) => widget.builder(context, index),
    ),);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
