import 'dart:async';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:html/parser.dart';
import 'package:html/dom.dart';
import '../../../utils/http.dart';
import '../model/model.dart';
import '../model/site.dart';

/// 站点内容解析器，通过加载JSON配置抓取网页内容，并封装成数据集
///
/// @author tsukiseele
/// @date 2022.8.8
/// @license Apache License 2.0

final REG_PAGE_TEMPLATE = RegExp(r"\{page\s*?:\s*?(-?\d*)[,\s]*?(-?\d*?)\}");
final REG_PAGE_MATCH = RegExp(r"\{page\s*?:.*?\}");
final REG_KEYWORD_TEMPLATE = RegExp(r"\{keywords\s*?:\s*?(.*?)\}");
final REG_KEYWORD_MATCH = RegExp(r"\{keywords\s*?:.*?\}");
final REG_SELECTOR_TEMPLATE = RegExp(r"\$\((.+?)\)\.(\w+?)\((.*?)\)");

class Mio<T extends Model> {
  Site? site;
  int page = 1;
  String? keywords;
  static Future<String> Function(String url, {Map<String, String>? headers})? _request;

  static void setRequest(Future<String> Function(String url, {Map<String, String>? headers})? request) {
    _request = request;
  }

  Mio(this.site);

  void setPage(int page) {
    this.page = page;
  }

  void setKeywords(String keywords) {
    this.keywords = keywords;
  }

  /// 解析Site对象，返回结果集
  /// @returns {Promise<<T extends Meta>[]>}
  Future<List<Map<String, dynamic>>> parseSite([bool isParseChildren = false]) async {
    return await parseSection(getCurrentSection()!, isParseChildren);
  }

  /// 解析Section对象，返回结果集
  /// @param {Section} section 站点板块
  /// @param {Number} deep 解析深度
  /// @return {Promise<<T extends Meta>[]>}
  Future<List<Map<String, dynamic>>> parseSection(Section section, [bool isParseChildren = false]) async {
    if (site == null) throw Exception('site cannot be empty!');
// 复用规则，现在已经在SiteLoader中处理
    if (section.reuse != null) {
      section.rules = site?.sections?['${section.reuse}']?.rules;
    }
    final result = await parseRules(section.index!, section.rules!);
    for (var item in result) {
      item[r'$section'] = section;
      item[r'$site'] = site;
    }
    if (isParseChildren && section.rules?[r'$children'] != null) {
      await parseChildrenOfList(result, section.rules!);
    }
    print('RESULT: $result');
    return result;
  }

  Future<void> parseChildrenOfList(List<Map<String, dynamic>> list, Rules rules) async {
    await Future.wait(list.map((item) => parseChildrenConcurrency(item, rules)));
// await Promise.allSettled(list.map((item) => this.parseChildrenConcurrency(item, rules)))
  }

  /// 解析Children，自动检测末尾，自动继承父级，自动拉平单节点子级
  /// @param {*} item
  /// @param {*} rules
  /// @return {Promise<T extends Meta>}
  Future<Map<String, dynamic>> parseChildrenConcurrency(Map<String, dynamic> item, Rules rules) async {
    if (item[r'$children'] != null && rules[r'$children'] != null) {
      List<Map<String, dynamic>> histroy = [];
      int page = 0;
      Selector $children = rules[r'$children']!;
      do {
        final children = await parseRules(item[r'$children']!, $children.rules!, page = page++);
// if (children && histroy && children.length && histroy.length && children.length === histroy.length && this.objectEquals(children[0], histroy[0])) break
// if (children != null && children.length > 0 && histroy.isNotEmpty && children.length == histroy.length && this.objectEquals(children[0], histroy[0])) break;
//
// histroy = JSON.parse(JSON.stringify(children));
        if (children.length == histroy.length && children.equals(histroy)) break;

        if (children.isNotEmpty) {
// 解析下级子节点
          if (children.first[r'$children'] != null && rules[r'$children']?.rules != null) {
            await Future.wait(children.map((child) => parseChildrenConcurrency(child, rules[r'$children']?.rules as Rules)));
          }
          var ddd = $children;
          print('XXXYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY: ${ddd.toJson().toString()}');
// 判断是否拉平子节点，否则追加到子节点下
          if ($children.flat != null && $children.flat == true) {
            item.addAll(children.first);
            print('YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY: ${item.toString()}');
            break;
// Object.assign(item, children[0]);
//           break;
          } else {
// 判断并继承父节点字段
// extend && children.forEach((child, index) => (children[index] = Object.assign({}, item, child)))
          if ($children.extend == true) {
            // children.forEach((child) {
            //   item.keys
            // });
          }
          item['children'] != null ? item['children']?.addAll(children) : (item['children'] = children);
            // break;
          }
        }
      } while (histroy.isNotEmpty);
    }
    return item;
  }

  bool isEmpty(Object? o) {
    return o == null || o == "";
  }

  /// 解析Rule对象，返回结果集
  /// @param {Number} page 页码
  /// @param {Number} keywords 关键字
  /// @returns {Promise<<T extends Meta>[]>}
  Future<List<Map<String, dynamic>>> parseRules(String indexUrl, Rules rule, [int? page, String? keywords]) async {
    // 生成URL
    final url = replaceUrlTemplate(indexUrl, page ?? this.page, keywords ?? this.keywords);
    print('URL: $url');
    // 发送请求
    final html = await requestText(url, headers: site?.headers);
    // 检查无效响应
    if (isEmpty(html)) return [];
    // 加载文档
    final doc = parse(html);
    final List<Map<String, dynamic>> resultSet = [];
    // 遍历选择器集
    for (final k in rule.keys) {
      final exp = rule[k];
      print('EXP: regex=${exp?.regex}, selector=${exp?.selector}');
      // 使用正则匹配
      if (exp?.regex != null) {
        if (exp?.regex == '') return resultSet;
        var context = '';
        // 匹配选择器内容
        if (exp?.selector != null) {
          // 此处的选择器只应选择一个元素，否则result会被刷新为最后一个
          selectEach(doc, exp?.selector as String, (result) => (context = result));
        } else {
          context = doc.getElementsByTagName('html')[0].innerHtml;
          print('CONTeXT: $context');
        }
        // 匹配正则内容
        final regexp = RegExp(exp?.regex ?? '');
        var groups = List.of(regexp.allMatches(context));
        while (resultSet.length < groups.length) {
          resultSet.add(<String, dynamic>{});
        }
        groups.forEachIndexed((i, item) {
          final match = item.groupCount > 0 ? item.group(1) : item.group(0);
          resultSet[i][k] = replaceRegex(match ?? '', exp?.capture, exp?.replacement);
        });
      // 使用选择器匹配
      } else if (exp?.selector != null) {
        selectEach(doc, exp?.selector as String, (result, index) {
          // print('RRRR: $result, IIII: $index');
          while (resultSet.length < index + 1) {
            resultSet.add(<String, dynamic>{});
          }
          // 执行最终替换，并添加到结果集
          resultSet[index][k] = replaceRegex(result, exp?.capture, exp?.replacement);
        });
      }
    }
    print('RESULT SET === $resultSet');
    for (var item in resultSet) {
      item['type'] = site?.type ?? 'unknown';
    }
    return resultSet; // resultSet;
  }

  /// 请求文档内容，默认使用fetch发送请求，自动注入请求头
  /// @param {String} url 链接
  /// @param {Object} options 操作
  /// @returns {Promise<String>} 响应文本
  Future<String> requestText(String url, {Map<String, String>? headers}) async {
    print('RRRRRRRRRRRRRREQ: $url');
    if (_request == null) {
      final response = await Dio().get(url, options: Options(responseType: ResponseType.plain, sendTimeout: 10000, headers: headers));
      return response.data.toString();
    }
    return await _request!(url, headers: headers);
  }

  /// 获取当前板块
  /// @returns {Section}
  Section? getCurrentSection() {
    if (site == null) throw Exception('site cannot be empty!');
    final section = keywords != null ? site?.sections!['search'] : site?.sections!["home"];
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
    final matches = REG_SELECTOR_TEMPLATE.allMatches(selector);
    if (matches.isEmpty) return;
    final match = matches.first;
    var select = match.groupCount > 0 ? match.group(1)! : throw Exception('empty selecor!!');
    final func = match.groupCount > 1 ? match.group(2) : 'text';
    final attr = match.groupCount > 2 ? match.group(3) : 'src';
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
      for (int index = 0; index < groups.groupCount + 1; index++) {
        // print('index: $index, group: ${groups.group(index)}');
        replacement = replacement?.replaceAll(RegExp("\\\$$index"), groups.group(index) ?? '');
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
    final pageMatches = REG_PAGE_TEMPLATE.allMatches(template);
    final keywordMatches  = REG_KEYWORD_TEMPLATE.allMatches(template);
    int p = page;
    String? k = '';
    if (keywordMatches.isNotEmpty) {
      final keywordMatch = keywordMatches.first;
       k = keywordMatch.groupCount > 1 ? keywordMatch.group(1) : '';
    }
    if (pageMatches.isNotEmpty) {
      final pageMatch = pageMatches.first;
      print('template: [$template], page: [$page], keywords: [$keywords]');
      print('PAGE SIZE: ${pageMatch.groupCount}, G0: [${pageMatch.group(0)}], G1: [${pageMatch.group(1)}], G2: [${pageMatch.group(2)}]');
      final offset = pageMatch.groupCount > 0 && (pageMatch.group(1)?.isNotEmpty ?? false) ? p + int.parse(pageMatch.group(1) ?? '0') : 0;
      final range = pageMatch.groupCount > 1 && (pageMatch.group(2)?.isNotEmpty ?? false) ? p * int.parse(pageMatch.group(2) ?? '1') : 1;
      p = (p + offset) * range;

      print('FINAL PAGE: [$p] offset: [$offset], range: [$range]');
    }
    return template.replaceAll(REG_PAGE_MATCH, p.toString()).replaceAll(REG_KEYWORD_MATCH, keywords ?? k ?? '');
  }
}
