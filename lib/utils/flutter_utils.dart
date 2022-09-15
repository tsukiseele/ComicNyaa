import 'package:flutter/material.dart';

class RouteUtil {
  RouteUtil._();

  static push(BuildContext context, Widget widget) {
    Navigator.push(context, MaterialPageRoute(builder: (ctx) => widget));
    // Navigator.push(context, SlideRightRoute(page: widget));
  }
}