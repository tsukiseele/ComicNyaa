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

class BackControl extends StatefulWidget {
  const BackControl({Key? key, required this.child, this.onBack}) : super(key: key);
  final Widget child;
  final bool Function()? onBack;

  @override
  State<StatefulWidget> createState() => _BackControlState();
}

class _BackControlState extends State<BackControl> {
  // final globalKey = GlobalKey<ScaffoldState>();
  DateTime? _currentBackPressTime = DateTime.now();

  @override
  Widget build(BuildContext context) =>
    WillPopScope(onWillPop: onWillPop, child: widget.child);

  Future<bool> onWillPop() {
    if (widget.onBack?.call() == false) return Future.value(false);
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
