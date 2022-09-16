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

enum TriangleDirection { topLeft, topRight, bottomLeft, bottomRight }

class TrianglePainter extends CustomPainter {
  final Color strokeColor;
  final PaintingStyle paintingStyle;
  final double strokeWidth;
  final TriangleDirection direction;

  TrianglePainter(
      {this.strokeColor = Colors.black,
      this.strokeWidth = 3,
      this.paintingStyle = PaintingStyle.fill,
      this.direction = TriangleDirection.topLeft});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..style = paintingStyle;

    canvas.drawPath(getTrianglePath(size.width, size.height), paint);
  }

  Path getTrianglePath(double x, double y) {
    switch (direction) {
      case TriangleDirection.topLeft:
        return Path()
          ..moveTo(0, 0)
          ..lineTo(0, y)
          ..lineTo(x, 0)
          ..lineTo(0, 0);
      case TriangleDirection.topRight:
        return Path()
          ..moveTo(x, 0)
          ..lineTo(0, 0)
          ..lineTo(x, y)
          ..lineTo(x, 0);
      case TriangleDirection.bottomLeft:
        return Path()
          ..moveTo(0, y)
          ..lineTo(x, y)
          ..lineTo(0, 0)
          ..lineTo(0, y);
      case TriangleDirection.bottomRight:
        return Path()
          ..moveTo(x, y)
          ..lineTo(0, y)
          ..lineTo(x, 0)
          ..lineTo(x, y);
    }
  }

  @override
  bool shouldRepaint(TrianglePainter oldDelegate) {
    return oldDelegate.strokeColor != strokeColor ||
        oldDelegate.paintingStyle != paintingStyle ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

Widget triangle({
  Widget? child,
  double width = 64,
  double height = 64,
  Color color = Colors.black,
  TriangleDirection direction = TriangleDirection.topLeft,
  Alignment? contentAlignment,
  EdgeInsets contentPadding = EdgeInsets.zero,
}) {
  if (contentAlignment == null) {
    switch (direction) {
      case TriangleDirection.topLeft:
        contentAlignment = Alignment.topLeft;
        break;
      case TriangleDirection.topRight:
        contentAlignment = Alignment.topRight;
        break;
      case TriangleDirection.bottomLeft:
        contentAlignment = Alignment.bottomLeft;
        break;
      case TriangleDirection.bottomRight:
        contentAlignment = Alignment.bottomRight;
        break;
    }
  }
  return CustomPaint(
      size: Size(width, height),
      painter: TrianglePainter(strokeColor: color, direction: direction),
      child: Container(
        width: width,
        height: height,
        alignment: contentAlignment,
        padding: contentPadding,
        child: child,
      ));
}
