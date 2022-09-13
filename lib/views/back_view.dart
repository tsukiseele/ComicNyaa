import 'package:flutter/material.dart';

class BackView extends StatefulWidget {
  const BackView({Key? key, required this.child}) : super(key: key);
  final Widget child;

  @override
  State<StatefulWidget> createState() => _BackViewState();
}

class _BackViewState extends State<BackView> {
  final globalKey = GlobalKey<ScaffoldState>();
  DateTime? _currentBackPressTime = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(onWillPop: onWillPop, child: widget.child);
  }

  Future<bool> onWillPop() {
    if (globalKey.currentState?.isDrawerOpen == true) {
      globalKey.currentState?.closeDrawer();
      return Future.value(false);
    }
    if (globalKey.currentState?.isEndDrawerOpen == true) {
      globalKey.currentState?.closeEndDrawer();
      return Future.value(false);
    }
    DateTime now = DateTime.now();
    if (_currentBackPressTime == null ||
        now.difference(_currentBackPressTime!) > const Duration(seconds: 2)) {
      _currentBackPressTime = now;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('再按一次退出')));
      return Future.value(false);
    }
    return Future.value(true);
  }
}
