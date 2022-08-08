// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:comic_nyaa/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // String regexString = r'\$\((.+?)\)\.(\w+?)\((.*?)\)'; // not r'/api/\w+/\d+/' !!!
  // RegExp regExp = RegExp(regexString);
  // var matches = regExp.allMatches(r"$(ul#post-list-posts > li).attr(src)");
  var matches = RegExp(r'\$\((.+?)\)\.(\w+?)\((.*?)\)').allMatches(r"$(ul#post-list-posts > li).attr(src)");
  // $(ul#post-list-posts > li).attr(dfggfds)

  print("${matches.length}");       // => 1 - 1 instance of pattern found in string
  var match = matches.elementAt(0); // => extract the first (and only) match
  print("group count: ${match.groupCount}");       // => 1 - 1 instance of pattern found in string
  print("0: ${match.group(0)}");       // => /api/topic/3/ - the whole match
  print("1: ${match.group(1)}");       // => topic  - first matched group
  print("2: ${match.group(2)}");       // => 3      - second matched group
  print("3: ${match.group(3)}");       // => 3      - second matched group
  print("4: ${match.group(4)}");       // => 3      - second matched group
  print("5: ${match.group(5)}");       // => 3      - second matched group


  // final matches = RegExp(r"\$\((.+?)\)\.(\w+?)(dfggfds)").allMatches(r'$(ul#post-list-posts > li).attrdfggfds');//REG_SELECTOR_TEMPLATE.allMatches(selector);
  // final matches = RegExp(r"\$\((.+?)\)\.(\w+?)\((.*?)\)").allMatches(r'$(ul#post-list-posts > li).attr(dfggfds)');//REG_SELECTOR_TEMPLATE.allMatches(selector);
  //
  // // if (matches.isEmpty) return;
  // print(matches.length);
  // final match = matches.first;
  //
  // print('FFFF: ${match.groupCount}, $matches');
  //
  // for (int index = 0; index < match.groupCount; index++) {
  //   print('SSS: $index, ${match.group(index)}');
  // }
  // print('SSS: 4, ${match.group(4)}');
  return;
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ComicNyaa());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
