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

class InkStack extends StatelessWidget {
  const InkStack(
      {Key? key,
      this.alignment = AlignmentDirectional.topStart,
      this.textDirection,
      this.fit = StackFit.loose,
      this.clipBehavior = Clip.hardEdge,
      required this.children,
      this.splashColor,
      this.onTap,
      this.onLongPress})
      : super(key: key);
  final List<Widget> children;
  final AlignmentGeometry alignment;
  final TextDirection? textDirection;
  final StackFit fit;
  final Clip clipBehavior;
  final void Function()? onTap;
  final void Function()? onLongPress;
  final Color? splashColor;

  @override
  Widget build(BuildContext context) => Stack(
      alignment: alignment,
      textDirection: textDirection,
      fit: fit,
      clipBehavior: clipBehavior,
      children: List.generate(children.length + 1, (index) {
        if (index < children.length) return children[index];
        return Positioned.fill(
            child: Material(
                color: Colors.transparent,
                child: InkWell(
                  splashColor: splashColor ?? Theme.of(context).primaryColor,
                  onTap: onTap,
                  onLongPress: onLongPress,
                )));
      }));
}
