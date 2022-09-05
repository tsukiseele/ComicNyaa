import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:comic_nyaa/library/mio/core/mio_loader.dart';
import 'package:comic_nyaa/library/mio/model/data_origin.dart';
import 'package:html/parser.dart';
import 'package:html/dom.dart';
import '../model/model.dart';
import '../model/site.dart';

/// 站点内容解析器，通过加载JSON配置抓取网页内容，并返回JSON数据
/// （因为Flutter不支持运行时反射，故不使用反射构建）
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
  final Site? _site;
  int _page = 1;
  String? _keywords;
  String? _sectionName;

  static Future<String> Function(String url, {Map<String, String>? headers})
      _request = (url, {Map<String, String>? headers}) async {
    HttpClientRequest request = await HttpClient().getUrl(Uri.parse(url));
    headers?.forEach((key, value) => request.headers.add(key, value));
    HttpClientResponse response = await request.close();
    return await response.transform(utf8.decoder).join();
  };

  static void setCustomRequest(
      Future<String> Function(String url, {Map<String, String>? headers})
          request) {
    _request = request;
  }

  Mio(this._site);

  void setPage(int page) {
    _page = page;
  }

  void setKeywords(String keywords) {
    _keywords = keywords;
  }

  void setSectionName(String sectionName) {
    _sectionName = sectionName;
  }

  /// 解析Site对象，返回结果集
  /// @returns {Promise<<T extends Meta>[]>}
  Future<List<Map<String, dynamic>>> parseSite(
      [bool isParseChildren = false]) async {
    final site = _site;
    final sectionName = currentSectionName;
    if (site == null) throw Exception('Site cannot be null!');
    if (sectionName == null) throw Exception('Section cannot be null!');
    return await parseSection(site, sectionName, isParseChildren);
  }

  /// 解析Section对象，返回结果集
  /// @param [Section] section 站点板块
  /// @return [bool] isParseChildren
  Future<List<Map<String, dynamic>>> parseSection(Site site, String sectionName,
      [bool isParseChildren = false]) async {
    final section = site.sections![sectionName];
    if (section == null) {
      throw Exception('Not found avaliable section: $sectionName');
    }
    // 复用规则
    if (section.reuse != null) {
      section.rules = site.sections?['${section.reuse}']?.rules;
    }
    final result = await parseRules(section.index!, section.rules!);
    for (var item in result) {
      item[r'$origin'] = DataOriginInfo(site.id!, sectionName).toJson();
    }
    if (isParseChildren && section.rules?[r'$children'] != null) {
      await parseAllChildrenOfList(result, section.rules!);
    }
    // print('RESULT: $result');
    return result;
  }

  Future<void> parseAllChildrenOfList(
      List<Map<String, dynamic>> list, Rules rules) async {
    await Future.wait(list.map((item) => parseAllChildren(item)));
  }

  /// 递归解析可用的子数据集合，可能会发送大量的网络请求
  /// 自动检测末尾，自动继承父级，自动拉平单节点子级
  ///
  /// @param {*} item
  /// @param {*} rules
  /// @return {Promise<T extends Meta>}
  Future<Map<String, dynamic>> parseAllChildren(Map<String, dynamic> item,
      {Future<bool> Function(List<Map<String, dynamic>>)? callback}) async {
    final Model model = Model.fromJson(item);
    final DataOriginInfo dataOriginInfo =
        DataOriginInfo.fromJson(item[r'$origin']);
    final depth = dataOriginInfo.depth ?? 0;
    final DataOrigin dataOrigin = model.getOrigin();
    final section = getChildSectionByDepth(dataOrigin.section, depth);
    final rules = section.rules!;
    if (item[r'$children'] != null && rules[r'$children'] != null) {
      int page = 0;
      Selector $children = rules[r'$children']!;
      String url = item[r'$children'];
      List<String> keys = [];
      final isMulitPage = url.contains(REG_PAGE_MATCH);
      do {
        final children = await parseRules(
            url, $children.rules!, page = page, _keywords = '');
        page++;
        // 获取唯一键，用于判断
        List<String> newKeys = isMulitPage
            ? children.map((item) => item[r'$key'].toString()).toList()
            : [];
        // 判断解析末尾
        if (isMulitPage &&
            keys.length == newKeys.length &&
            keys.equals(newKeys)) break;
        keys = newKeys;
        // 生成新的数据源
        final newOriginInfo = DataOriginInfo(
                dataOriginInfo.siteId, dataOriginInfo.sectionName,
                depth: depth + 1)
            .toJson();
        // 递归解析Children
        if (children.isNotEmpty) {
          final nextChildren = rules[r'$children']?.rules;
          if (children.first[r'$children'] != null && nextChildren != null) {
            await Future.wait(children.map((child) {
              child[r'$origin'] = newOriginInfo;
              return parseAllChildren(child);
            }));
          }
          // 操作参数处理
          print('SELECTOR: ${$children.toJson().toString()}');
          // 判断是否拉平子节点，否则追加到子节点下
          if ($children.flat != null && $children.flat == true) {
            item.addAll(children.first);
            print('FLAT CHILDREN ITEM: ${item.toString()}');
            break;
          } else {
            if ($children.extend == true) {
              // 判断并继承父节点字段
              // extend && children.forEach((child, index) => (children[index] = Object.assign({}, item, child)))
            }
            item['children'] != null
                ? item['children']?.addAll(children)
                : (item['children'] = children);
            if (callback != null) {
              await callback(children);
            }
          }
        }
      } while (isMulitPage && keys.isNotEmpty);
    }
    return item;
  }

  ///
  ///
  bool equalsKeys(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    return a.whereIndexed((index, element) => a[index] == b[index]).length ==
        a.length;
  }

  /// 解析可用的子数据集合<br />
  /// 若<strong>deep = true</strong>，会递归解析。<br />
  /// 返回JSON数据流
  Stream<List<Map<String, dynamic>>> parseChildren(
      {required Map<String, dynamic> item, bool deep = false}) async* {
    final Model model = Model.fromJson(item);
    final DataOriginInfo dataOriginInfo =
        DataOriginInfo.fromJson(item[r'$origin']);
    final DataOrigin dataOrigin = model.getOrigin();
    final depth = dataOriginInfo.depth ?? 0;
    final site = dataOrigin.site;
    final section = getChildSectionByDepth(dataOrigin.section, depth);
    final rules = section.rules!;
    // print('parseChildren(): RULES: ${rules.toJson().toString()}');
    if (item[r'$children'] != null && rules[r'$children'] != null) {
      int page = 0;
      Selector $children = rules[r'$children']!;
      String urlTemplate = item[r'$children'];
      List<String> keys = [];
      final isMulitPage = urlTemplate.contains(REG_PAGE_MATCH);
      do {
        final url = _parseUrlTemplate(urlTemplate, page, '');
        // print('parseChildren(): URL: $url');
        // 发送请求
        final html = await _requestText(url, headers: site.headers);
        // print('PARSE CHILDREN START =======================================');
        List<Map<String, dynamic>> children =
            parseRulesFromHtml(html, $children.rules!);
        if (children.isEmpty) break;
        // print('parseChildren(): PARSE CHILDREN LENGTH ======================================= ${children.length}');
        List<String> newKeys = isMulitPage
            ? children.map((item) => item[r'$key'].toString()).toList()
            : [];
        // print('parseChildren(): PARSE EQ ======================================= $keys === $newKeys');
        if (isMulitPage && equalsKeys(keys, newKeys)) break;
        keys = newKeys;
        page++;
        final newOriginInfo = DataOriginInfo(
                dataOriginInfo.siteId, dataOriginInfo.sectionName,
                depth: depth + 1)
            .toJson();
        // 解析下级子节点
        if (deep) {
          final nextChildren = rules[r'$children']?.rules;
          if (children.first[r'$children'] != null && nextChildren != null) {
            await Future.wait(children.map((child) {
              child[r'$origin'] = newOriginInfo;
              return parseChildren(item: child).toList();
            }));
          }
        }
        // 判断是否拉平子节点(并终止获取)，否则追加到子节点下，
        if ($children.flat != null && $children.flat == true) {
          item.addAll(children.first);
          yield [item];
          break;
        } else {
          // 构建解析状态
          children.forEachIndexed((i, child) => child[r'$origin'] = newOriginInfo);
          // 判断是否继承父节点字段
          if ($children.extend == true) {
            // extend && children.forEach((child, index) => (children[index] = Object.assign({}, item, child)))
          }
          item['children'] != null
              ? item['children']?.addAll(children)
              : (item['children'] = children);
          // print('YIDLE START =======================================');
          yield children;
          // print('YIDLE END =======================================');
        }
      } while (isMulitPage && keys.isNotEmpty);
    }
  }

  Section getChildSectionByDepth(Section section, int depth) {
    Section childSection = section;
    for (int i = depth; i > 0; i--) {
      Rules? childRules = section.rules?[r'$children']?.rules;
      childSection = Section(rules: childRules);
    }
    return childSection;
  }

  bool isEmpty(Object? o) {
    return o == null || o == "";
  }

  /// 解析Rule对象，返回结果集
  /// @param {String} html HTML文档
  /// @param {Rules} rules 解析规则
  /// @returns {List<Map<String, dynamic>>}
  List<Map<String, dynamic>> parseRulesFromHtml(String html, Rules rule) {
    // 检查无效响应
    if (html.trim().isEmpty) return [];
    // 加载文档
    final doc = parse(html);
    final List<Map<String, dynamic>> resultSet = [];
    final Map<String, List<String>> mergeSet = {};
    // 遍历选择器集
    for (final k in rule.keys) {
      final exp = rule[k]!;
      // print('EXP: regex=${exp?.regex}, selector=${exp?.selector}');
      final props = <String>[];
      // 使用正则匹配
      if (exp.regex != null) {
        var content = doc.outerHtml;
        // 匹配选择器内容
        if (exp.selector != null) {
          // 此处的选择器只应选择一个元素，否则result会被刷新为最后一个
          selectEach(doc, exp.selector!, (result, index) => (content = result));
        }
        // 匹配正则内容
        final regexp = RegExp(exp.regex ?? '');
        var groups = List.of(regexp.allMatches(content));

        groups.forEachIndexed((i, item) {
          final match = item.groupCount > 0 ? item.group(1) : item.group(0);
          final value = _parseRegex(match ?? '', exp.capture, exp.replacement);
          props.add(value);
        });
        // 使用选择器匹配
      } else if (exp.selector != null) {
        selectEach(doc, exp.selector as String, (result, index) {
          // print('RRRR: $result, IIII: $index');
          // 执行最终替换，并添加到结果集
          final value = _parseRegex(result, exp.capture, exp.replacement);
          props.add(value);
        });
      }
      // 组合数据
      if (exp.merge == true) {
        mergeSet[k] = props;
      } else {
        while (resultSet.length < props.length) {
          resultSet.add(<String, dynamic>{});
        }
        props.forEachIndexed((i, prop) => resultSet[i][k] = prop);
      }
    }
    // 处理合并属性
    mergeSet.forEach((key, value) {
      final mergeProp = value.join(',');
      for (var item in resultSet) {
        item[key] = mergeProp;
      }
    });
    print('RESULT SET === $resultSet');
    // 注入类型
    for (var item in resultSet) {
      item['type'] = _site?.type ?? 'unknown';
    }
    return resultSet;
  }

  /// 解析Rule对象，返回结果集
  /// @param {Number} page 页码
  /// @param {Number} keywords 关键字
  /// @returns {Promise<<T extends Meta>[]>}
  Future<List<Map<String, dynamic>>> parseRules(String indexUrl, Rules rule,
      [int? page, String? keywords]) async {
    // 生成URL
    final url =
        _parseUrlTemplate(indexUrl, page ?? _page, keywords ?? _keywords);
    print('REQUEEST: $url');
    print('REQUEEST RULES: ${rule.keys}');

    // 发送请求
    final html = await _requestText(url, headers: _site?.headers);

    // 检查无效响应
    if (html.trim().isEmpty) return [];
    // print('HTMl: ${html}');
    // 解析文档
    return parseRulesFromHtml(html, rule);
  }

  /// 请求文档内容，默认使用fetch发送请求，自动注入请求头
  /// @param {String} url 链接
  /// @param {Object} options 操作
  /// @returns {Promise<String>} 响应文本
  Future<String> _requestText(String url,
      {Map<String, String>? headers}) async {
    return await _request(url, headers: headers);
  }

  /// 获取当前板块
  /// @returns {Section}
  String? get currentSectionName {
    return _sectionName ?? (_keywords == null ? 'home' : 'search');
  }

  /// 遍历选择器
  /// @param {cheerio.CheerioAPI} $ 文档上下文
  /// @param {string} selector 选择器
  /// @param {function} each (content: string, index: number) => void
  selectEach(
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
  String _parseRegex(String text, String? capture, String? replacement) {
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
  String _parseUrlTemplate(String template, int page, String? keywords) {
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
}
