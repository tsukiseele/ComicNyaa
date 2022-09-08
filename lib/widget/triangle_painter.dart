import 'dart:math';

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
        width: width / 2,
        height: height / 2,
        alignment: contentAlignment,
        padding: contentPadding,
        child: child,
      ));
}
