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

import 'package:flutter/material.dart';

class NyaaTagItem extends StatefulWidget {
  const NyaaTagItem({Key? key, required this.text, this.color, this.onTap, this.onLongPress, this.isRounded = true, this.textStyle, this.padding})
      : super(key: key);
  final String text;
  final TextStyle? textStyle;
  final Color? color;
  final bool isRounded;
  final void Function()? onTap;
  final void Function()? onLongPress;
  final EdgeInsets? padding;

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
            borderRadius: widget.isRounded ? BorderRadius.circular(16) : BorderRadius.zero,
            elevation: 2,
            child: InkWell(
                onTap: widget.onTap,
                onLongPress: widget.onLongPress,
                child: Padding(
                    padding: widget.padding ?? const EdgeInsets.only(left: 8, top: 4, right: 8, bottom: 4),
                    child: Text(
                      widget.text,
                      style: widget.textStyle ?? const TextStyle(fontSize: 16, color: Colors.white),
                    )))));
  }

  @override
  void dispose() {
    super.dispose();
  }
}
