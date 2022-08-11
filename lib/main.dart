import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';


import 'views/pages/home_page_view.dart';

void main() async {
  runApp(const ComicNyaa());
}

class ComicNyaa extends StatefulWidget {
  const ComicNyaa({Key? key}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _ComicNyaaState();
}

class _ComicNyaaState extends State<ComicNyaa> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ComicNyaa',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: const MainView(title: 'Home'),
    );
  }
  @override
  void initState() {
    setOptimalDisplayMode();
    super.initState();
  }

  Future<void> setOptimalDisplayMode() async {
    final List<DisplayMode> supported = await FlutterDisplayMode.supported;
    final DisplayMode active = await FlutterDisplayMode.active;
    final List<DisplayMode> sameResolution = supported
        .where((DisplayMode m) => m.width == active.width && m.height == active.height)
        .toList()
      ..sort((DisplayMode a, DisplayMode b) => b.refreshRate.compareTo(a.refreshRate));

    final DisplayMode mostOptimalMode = sameResolution.isNotEmpty ? sameResolution.first : active;
    /// This setting is per session.
    /// Please ensure this was placed with `initState` of your root widget.
    await FlutterDisplayMode.setPreferredMode(mostOptimalMode);
  }
}
