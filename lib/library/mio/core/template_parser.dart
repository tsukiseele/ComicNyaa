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

import 'package:collection/collection.dart';
import 'package:html/dom.dart';

class TemplateParser {

  static final REG_PAGE_TEMPLATE = RegExp(r"\{page\s*?:\s*?(-?\d*)[,\s]*?(-?\d*?)\}");
  static final REG_PAGE_MATCH = RegExp(r"\{page\s*?:.*?\}");
  static final REG_KEYWORD_TEMPLATE = RegExp(r"\{keywords\s*?:\s*?(.*?)\}");
  static final REG_KEYWORD_MATCH = RegExp(r"\{keywords\s*?:.*?\}");
  static final REG_SELECTOR_TEMPLATE = RegExp(r"\$\((.+?)\)\.(\w+?)\((.*?)\)");
  /// 遍历选择器
  /// @param {cheerio.CheerioAPI} $ 文档上下文
  /// @param {string} selector 选择器
  /// @param {function} each (content: string, index: number) => void
  static eachSelector(
      Document doc, String selector, Function(String content, int index) each) {
    final matches = REG_SELECTOR_TEMPLATE.allMatches(selector);
    if (matches.isEmpty) return;
    final match = matches.first;
    var select = match.groupCount > 0
        ? match.group(1)!
        : throw Exception('empty selecor!!');
    final func = match.groupCount > 1 ? match.group(2) : 'text';
    final attr = match.groupCount > 2 ? match.group(3) : 'href';
    // 选择器语法兼容
    select = select.replaceAll(RegExp(r':eq\('), ':nth-child(');
    // 遍历元素集
    doc.querySelectorAll(select).forEachIndexed((index, el) {
      var result = '';
      switch (func) {
        case 'attr':
          result = el.attributes[attr] ?? '';
          break;
        case 'text':
          result = el.text;
          break;
        case 'html':
          result = el.innerHtml;
          break;
      }
      each(result, index);
    });
  }

  /// 替换正则式
  /// @param {String} text 文本
  /// @param {String} capture 截取式
  /// @param {String} replacement 替换式
  /// @returns {String} 结果
  static String parseRegex(String text, String? capture, String? replacement) {
    if (text == "") return replacement ?? "";
    if (capture == null || capture == "") return text;
    if (replacement == null || replacement == "") {
      final m = RegExp(capture).allMatches(text);
      return m.first.group(0) ?? text;
    }
    final result = RegExp(capture).allMatches(text);
    if (result.isNotEmpty) {
      final groups = result.first;
      for (int index = 0; index < groups.groupCount + 1; index++) {
        // print('index: $index, group: ${groups.group(index)}');
        replacement = replacement?.replaceAll(
            RegExp("\\\$$index"), groups.group(index) ?? '');
      }
    }
    return replacement ?? "";
  }

  /// 替换URL模板
  /// @param {String} template 模板
  /// @param {Number} page 当前页码
  /// @param {String} keywords 关键字
  /// @returns {String} 真实URL
  static String parseUrl(String template, int page, String? keywords) {
    final pageMatches = REG_PAGE_TEMPLATE.allMatches(template);
    final keywordMatches = REG_KEYWORD_TEMPLATE.allMatches(template);
    int p = page;
    String? k = '';
    if (keywordMatches.isNotEmpty) {
      final keywordMatch = keywordMatches.first;
      k = keywordMatch.groupCount > 1 ? keywordMatch.group(1) : '';
    }
    if (pageMatches.isNotEmpty) {
      final pageMatch = pageMatches.first;
      // print('TEMPLATE: [$template], page: [$page], keywords: [$keywords]');
      // print('MATCHES: ${pageMatch.groupCount}, G0: [${pageMatch.group(0)}], G1: [${pageMatch.group(1)}], G2: [${pageMatch.group(2)}]');
      final offset =
      pageMatch.groupCount > 0 && (pageMatch.group(1)?.isNotEmpty ?? false)
          ? int.parse(pageMatch.group(1) ?? '0')
          : 0;
      final range =
      pageMatch.groupCount > 1 && (pageMatch.group(2)?.isNotEmpty ?? false)
          ? int.parse(pageMatch.group(2) ?? '1')
          : 1;

      // print('BEFORE FINAL PAGE: [$p] offset: [$offset], range: [$range]');
      p = (p + offset) * range;
      // print('AFTER FINAL PAGE: [$p] offset: [$offset], range: [$range]');
    }
    return template
        .replaceAll(REG_PAGE_MATCH, p.toString())
        .replaceAll(REG_KEYWORD_MATCH, keywords ?? k ?? '');
  }

  static bool isMultiple(String urlTemplate) {
    return urlTemplate.contains(REG_PAGE_MATCH);
  }
}