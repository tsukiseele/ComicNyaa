import 'package:flutter/cupertino.dart';

class RouteUtil {
  RouteUtil._();

  static push(BuildContext context, Widget widget) {
    Navigator.push(context, CupertinoPageRoute(builder: (ctx) => widget));
  }
}