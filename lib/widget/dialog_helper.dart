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

class CustomDialog {
  CustomDialog(this.context, {required this.builder});

  final BuildContext context;
  final Widget Function(BuildContext context, CustomDialog dialag) builder;
  NavigatorState? _ns;

  show() {
    showDialog(
        context: context,
        builder: (ctx) {
          _ns = Navigator.of(ctx);
          return builder(ctx, this);
        });
  }

  dismiss() {
    _ns?.pop();
  }
}

class OptionsDialog {
  OptionsDialog(this.context,
      {this.title, this.titleStyle, required this.optionsBuilder});

  final BuildContext context;
  final String? title;
  final TextStyle? titleStyle;
  final List<Widget> Function(BuildContext context, CustomDialog dialog)
      optionsBuilder;

  CustomDialog show() {
    return CustomDialog(context,
        builder: (ctx, dialog) => SimpleDialog(
            title: title != null
                ? Text(title!,
                    style: titleStyle ?? const TextStyle(fontSize: 16))
                : null,
            children: optionsBuilder(context, dialog)))..show();
  }
}
