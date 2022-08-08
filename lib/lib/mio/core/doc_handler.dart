import 'dart:async';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:comic_nyaa/lib/mio/core/rule_loader.dart';
import 'package:dio/dio.dart';
import 'package:html/parser.dart';
import 'package:html/dom.dart';

import '../model/meta.dart';
import '../model/site.dart';

/// 站点内容解析器，通过加载JSON配置抓取网页内容，并封装成数据集
///
/// @author tsukiseele
/// @date 2022.6.20
/// @license MIT
// import * as cheerio from 'cheerio'

final REG_PAGE_TEMPLATE = RegExp(r"\{page\s*?:\s*?(-?\d*)[,\s]*?(-?\d*?)\}");
final REG_PAGE_MATCH = RegExp(r"\{page\s*?:.*?\}");
final REG_KEYWORD_TEMPLATE = RegExp(r"\{keywords\s*?:\s*?(.*?)\}");
final REG_KEYWORD_MATCH = RegExp(r"\{keywords\s*?:.*?\}");
final REG_SELECTOR_TEMPLATE = RegExp(r"\w+");

// final config = {
//
// request: async (url: string, options: RequestOptions) => {
// if (!fetch) throw new Error("fetch is not defined");
// const resp = await fetch(url, options)
// return resp.ok ? await resp.text() : ''
// }
// }
class Mio<T extends Meta> {
  // static var request = ()
  Site? site;
  int page = 1;
  String? keywords;

  Mio(this.site);

  Mio<T> setPage(int page) {
    this.page = page;
    return this;
  }

  Mio<T> setKeywords(String keywords) {
    this.keywords = keywords;
    return this;
  }

  /// 解析Site对象，返回结果集
  /// @returns {Promise<<T extends Meta>[]>}
  Future<List<Map<String, dynamic>>> parseSite(
      [bool isParseChildren = false]) async {
    return await parseSection(getCurrentSection()!, isParseChildren);
  }

  /// 解析Section对象，返回结果集
  /// @param {Section} section 站点板块
  /// @param {Number} deep 解析深度
  /// @return {Promise<<T extends Meta>[]>}
  Future<List<Map<String, dynamic>>> parseSection(Section section,
      [bool isParseChildren = false]) async {
    if (site == null) throw Exception('site cannot be empty!');
// 复用规则，现在已经在SiteLoader中处理
// if (section.reuse) {
//   section.rules = this.site.sections[section.reuse].rules
// }
    final result = await parseRules(section.index!, section.rules!);
    for (var item in result) {
      item[r'$section'] = section;
      item[r'$site'] = site;
    }
    // if (isParseChildren && section.rules?[r'$children'] != null) {
    //   await parseChildrenOfList(result, section.rules!);
    // }
    print('RESULT: ' + result.toString());
    return result;
  }

//   Future<void> parseChildrenOfList(List<T> list, Rules rules) async {
//     Future.wait(list.map((item) => parseChildrenConcurrency(item, rules)));
// // await Promise.allSettled(list.map((item) => this.parseChildrenConcurrency(item, rules)))
//   }

  /// 解析Children，自动检测末尾，自动继承父级，自动拉平单项子级
  /// @param {*} item
  /// @param {*} rules
  /// @return {Promise<T extends Meta>}
//   Future<T> parseChildrenConcurrency(T item, Rules rules,
//       [bool extend = true]) async {
//     if (item.$children != null && rules['\$children'] != null) {
//       List<T> histroy = List.empty();
//       int page = 0;
//       Selector $children = rules[r'$children']!;
// // do {
//       final children = await parseRules(item.$children!, $children.rules!, page = page++);
// // if (children && histroy && children.length && histroy.length && children.length === histroy.length && this.objectEquals(children[0], histroy[0])) break
// // if (children != null && children.length > 0 && histroy.isNotEmpty && children.length == histroy.length && this.objectEquals(children[0], histroy[0])) break;
// //
// // histroy = JSON.parse(JSON.stringify(children));
//       if (children.isNotEmpty) {
// // 解析下级子节点
//         if (children[0].$children != null &&
//             rules['$children']?.rules != null) {
//           await Future.wait(children.map((child) =>
//               parseChildrenConcurrency(
//                   child, rules['$children']?.rules as Rules)));
//         }
// // 判断是否拉平子节点，否则追加到子节点下
//         if ($children.flat != null && $children.flat == true) {
// // Object.assign(item, children[0]);
// //           break;
//         } else {
// // 判断并继承父节点字段
// // extend && children.forEach((child, index) => (children[index] = Object.assign({}, item, child)))
//           item.children != null ? item.children?.addAll(children) : (
//               item.children = children);
//           // break;
//         }
//       }
// // } while (histroy && histroy.length);
//     }
//     return item;
//   }

  bool isEmpty(Object? o) {
    return o == null || o == "";
  }

  /// 解析Rule对象，返回结果集
  /// @param {Number} page 页码
  /// @param {Number} keywords 关键字
  /// @returns {Promise<<T extends Meta>[]>}
  Future<List<Map<String, dynamic>>> parseRules(String indexUrl, Rules rule,
      [int page = 1, String keywords = '']) async {
    // 生成URL
    final url = replaceUrlTemplate(indexUrl, page, keywords);
    print('URL: $url');
    // 发送请求
    final html = await requestText(url, headers: site?.headers);
    // 检查无效响应
    if (isEmpty(html)) return [];
    // 加载文档
    final doc = parse(html); //cheerio.load(html);
    final List<Map<String, dynamic>> resultSet = [];
    // 遍历选择器集
    // for (const k of Object.keys(rule)) {
    for (final k in rule.keys) {
      final exp = rule[k];
      print('EXP: regex=${exp?.regex}, selector=${exp?.selector}');
      if (exp?.regex != null) {
        var context = '';
        // 匹配选择器内容
        if (exp?.selector != null) {
          // 此处的选择器只应选择一个元素，否则result会被刷新为最后一个
          selectEach(
              doc, exp?.selector as String, (result) => (context = result));
        } else {
          context = doc.getElementsByTagName('html').toString();
        }
        // 匹配正则内容
        final regexp = RegExp(exp?.regex as String);
        var groups = List.of(regexp.allMatches(context));

        groups.forEachIndexed((i, item) {
          while (resultSet.length < i) {
            resultSet.add(<String, dynamic>{});
          }
          resultSet[i][k] =
              replaceRegex(item.input, exp?.capture, exp?.replacement);
        });

// 以第一个组为匹配值
// resultSet[i] || resultSet.push({} as T)
// resultSet[i][k] = this.replaceRegex(res[1], exp.capture, exp.replacement)
//         }
      } else if (exp?.selector != null) {
        selectEach(doc, exp?.selector as String, (result, index) {
          print('RRRR: $result, IIII: $index');
          while (resultSet.length < index + 1) {
            resultSet.add(<String, dynamic>{});
          }
          // 执行最终替换，并添加到结果集
          resultSet[index][k] =
              replaceRegex(result, exp?.capture, exp?.replacement);
          ;
        });
      }
    }
    print('RESULT SET === $resultSet');
    return resultSet; // resultSet;
  }

  /// 请求文档内容，默认使用fetch发送请求，自动注入请求头
  /// @param {String} url 链接
  /// @param {Object} options 操作
  /// @returns {Promise<String>} 响应文本
  Future<String> requestText(String url, {dynamic headers}) async {
    final response = await Dio()
        .get(url, options: Options(responseType: ResponseType.plain));
    final html = response.data.toString();
    return html;
  }

  /// 获取当前板块
  /// @returns {Section}
  Section? getCurrentSection() {
    if (site == null) throw Exception('site cannot be empty!');
    final section =
    keywords != null ? site?.sections!['search'] : site?.sections!["home"];
// 复用规则
// if (section.reuse) {
//   section.rules = this.site.sections[section.reuse].rules
// }
    return section;
  }

  /// 遍历选择器
  /// @param {cheerio.CheerioAPI} $ 文档上下文
  /// @param {string} selector 选择器
  /// @param {function} each (content: string, index: number) => void
  selectEach(Document doc, String selector, Function each) {
    final matches = REG_SELECTOR_TEMPLATE.allMatches(selector);//RegExp(r"\$\((.+?)\)\.(\w+?)\((.*?)\)")
    if (matches.isEmpty) return;
    final match = matches.first;
    final select = match.groupCount > 1 ? match.group(1)! : '';
    final func = match.groupCount > 2 ? match.group(2) : 'text';
    final attr = match.groupCount > 3 ? match.group(3) : '';
    // 遍历元素集
    doc.querySelectorAll(select).forEachIndexed((index, el) {
      var result = '';
      switch (func) {
        case 'attr':
          result = el.attributes[attr] ?? '';
          break;
        case 'text':
        // result = $(el).text();
          result = el.toString();
          break;
        case 'html':
        // result = $(el).html() || '';
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
  String replaceRegex(String text, String? capture, String? replacement) {
    if (text == "") return replacement ?? "";
    if (capture == null || capture == "") return text;
    if (replacement == null || replacement == "") {
      final m = RegExp(capture).allMatches(text);
      return m.first.group(0) ?? text;
    }
    final result = RegExp(capture).allMatches(text);
    if (result.isNotEmpty) {
      final groups = result.first;
      for (int index = 0; index < groups.groupCount; index++) {
        print('index: $index, group: ${groups.group(index)}');
        replacement = replacement?.replaceAll(
            RegExp(r"\$" + index.toString()), groups.group(index) ?? '');
      }
    }
    return replacement ?? "";
  }

  /// 替换URL模板
  /// @param {String} template 模板
  /// @param {Number} page 当前页码
  /// @param {String} keywords 关键字
  /// @returns {String} 真实URL
  String replaceUrlTemplate(String template, int page, String? keywords) {
    final pageMatch = List.of(REG_PAGE_TEMPLATE.allMatches(template));
    final keywordMatch = List.of(REG_KEYWORD_TEMPLATE.allMatches(template));
    final k = keywordMatch.length > 1 ? keywordMatch[1].input : '';
    var p = 0;
    p = pageMatch.length > 1 ? p + int.parse(pageMatch[1].input) : p;
    p = pageMatch.length > 2 ? p * int.parse(pageMatch[2].input) : p;

    return template
        .replaceAll(REG_PAGE_MATCH, p.toString())
        .replaceAll(REG_KEYWORD_MATCH, keywords ?? k);
  }
}