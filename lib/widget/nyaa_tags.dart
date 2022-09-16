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

class NyaaTags extends StatefulWidget {
  const NyaaTags({
    Key? key, required this.builder, required this.itemCount,
  }) : super(key: key);
  final IndexedWidgetBuilder builder;
  final int itemCount;

  @override
  State<StatefulWidget> createState() {
    return _NyaaTagsState();
  }
}

class _NyaaTagsState extends State<NyaaTags>
    with TickerProviderStateMixin<NyaaTags> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 1,
      runSpacing: 1,
      children: List.generate(
      widget.itemCount,
          (index) => widget.builder(context, index),
    ),);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
