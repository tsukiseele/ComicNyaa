import 'package:flutter/material.dart';

class RouteUtil {
  RouteUtil._();

  static push(BuildContext context, Widget widget) {
    Navigator.push(context, MaterialPageRoute(builder: (ctx) => widget));
    // Navigator.push(context, SlideRightRoute(page: widget));
  }
}

class ColorUtil {
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}