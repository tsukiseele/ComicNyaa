import 'package:flutter/material.dart';

class NyaaTagItem extends StatefulWidget {
  const NyaaTagItem({Key? key, required this.text, this.color, this.onTap, this.onLongPress})
      : super(key: key);
  final String text;
  final Color? color;
  final void Function()? onTap;
  final void Function()? onLongPress;

  @override
  State<StatefulWidget> createState() {
    return _NyaaTagItemState();
  }
}

class _NyaaTagItemState extends State<NyaaTagItem>
    with TickerProviderStateMixin<NyaaTagItem> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.all(4),
        child: Material(
            color:
                widget.color ?? Colors.white60, //Theme.of(context).primaryColor
            borderRadius: BorderRadius.circular(16),
            elevation: 2,
            child: InkWell(
                onTap: widget.onTap,
                onLongPress: widget.onLongPress,
                child: Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4, right: 8, bottom: 4),
                    child: Text(
                      widget.text,
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    )))));
  }

  @override
  void dispose() {
    super.dispose();
  }
}
