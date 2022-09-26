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

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:html/parser.dart';
import '../core/template_parser.dart';
import '../model/data_origin.dart';
import '../model/data_model.dart';
import '../model/site.dart';

/// 站点内容解析器，通过加载JSON配置抓取网页内容，并返回JSON数据
/// （因为Flutter不支持运行时反射，故不使用反射构建）
class Mio<T extends DataModel> {
  final Site? _site;
  int _page = 1;
  String? _keywords;
  String? _sectionName;

  static Future<String> Function(String url, {Map<String, String>? headers}) get requestAsText => _request;

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
      item[k$origin] = DataOriginInfo(site.id!, sectionName).toJson();
    }
    if (isParseChildren && section.rules?[k$children] != null) {
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
    final DataModel model = DataModel.fromJson(item);
    final DataOriginInfo dataOriginInfo =
        DataOriginInfo.fromJson(item[k$origin]);
    final DataOrigin dataOrigin = model.getOrigin();
    final depth = dataOriginInfo.depth ?? 0;
    final section = dataOrigin.getChildSectionByDepth(depth);
    final rules = section.rules!;
    final Selector? childrenSelector = rules[k$children];
    final String? url = item[k$children];
    if (url != null && childrenSelector?.rules != null) {
      final isMulitPage = url.contains(TemplateParser.REG_PAGE_MATCH);
      int page = 0;
      List<String> keys = [];
      do {
        final children = await parseRules(
            url, childrenSelector!.rules!, page = page, _keywords = '');
        page++;
        // 获取唯一键，用于对比
        final List<String> newKeys = isMulitPage
            ? children.map((item) => item[k$key].toString()).toList()
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
          final nextChildren = childrenSelector.rules;
          if (children.first[k$children] != null && nextChildren != null) {
            await Future.wait(children.map((child) {
              child[k$origin] = newOriginInfo;
              return parseAllChildren(child);
            }));
          }
          // 操作参数处理
          // print('SELECTOR: ${childrenSelector.toJson().toString()}');
          // 判断是否拉平子节点，否则追加到子节点下
          if (childrenSelector.flat == true) {
            item.addAll(children.first);
            // print('FLAT CHILDREN ITEM: ${item.toString()}');
            break;
          } else {
            if (childrenSelector.inherit == true) {
              // 判断并继承父节点字段
              // extend && children.forEach((child, index) => (children[index] = Object.assign({}, item, child)))
            }
            item[fieldChildren] != null
                ? item[fieldChildren]?.addAll(children)
                : (item[fieldChildren] = children);
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

  /// 解析扩展属性，只作用于顶层Section
  ///
  /// 返回扩展后的DataModel
  Future<Map<String, dynamic>> parseExtended(
      {required Map<String, dynamic> item, bool deep = false}) async {
    final DataModel model = DataModel.fromJson(item);
    final DataOrigin dataOrigin = model.getOrigin();
    final site = dataOrigin.site;
    final rules = dataOrigin.section.rules!;
    // print('parseExtended(): RULES: ${rules.toJson().toString()}');
    final Selector? extendedSelector = rules[k$extended];
    final String? urlTemplate = item[k$extended];
    // print('parseExtended()::: $urlTemplate, $extendedSelector');
    if (urlTemplate != null && extendedSelector?.rules != null) {
      final url = TemplateParser.parseUrl(urlTemplate, 0, '');
      final html = await _requestText(url, headers: site.headers);
      final List<Map<String, dynamic>> children =
          parseRulesFromHtml(html, extendedSelector!.rules!);
      item.addAll(children.first);
    }
    return item;
  }

  /// 解析可用的子数据集合<br />
  /// 若<strong>deep = true</strong>，会递归解析。<br />
  /// 返回JSON数据流
  Stream<List<Map<String, dynamic>>> parseChildren(
      {required Map<String, dynamic> item, bool deep = false}) async* {
    final DataModel model = DataModel.fromJson(item);
    final DataOriginInfo dataOriginInfo =
        DataOriginInfo.fromJson(item[k$origin]);
    final DataOrigin dataOrigin = model.getOrigin();
    final depth = dataOriginInfo.depth ?? 0;
    final site = dataOrigin.site;
    final section = dataOrigin.getChildSectionByDepth(depth);
    final rules = section.rules!;
    // print('parseChildren(): RULES: ${rules.toJson().toString()}');
    final Selector? childrenSelector = rules[k$children];
    final String? urlTemplate = item[k$children];
    if (urlTemplate != null && childrenSelector?.rules != null) {
      final isMulitPage = TemplateParser.isMultiple(urlTemplate);
      int page = 0;
      List<String> keys = [];
      do {
        final url = TemplateParser.parseUrl(urlTemplate, page, '');
        // print('parseChildren(): URL: $url');
        // 发送请求
        final html = await _requestText(url, headers: site.headers);
        // print('PARSE CHILDREN START =======================================');
        final List<Map<String, dynamic>> children =
            parseRulesFromHtml(html, childrenSelector!.rules!);
        if (children.isEmpty) break;
        // print('parseChildren(): PARSE CHILDREN LENGTH ======================================= ${children.length}');
        final List<String> newKeys = isMulitPage
            ? children.map((item) => item[k$key].toString()).toList()
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
          final nextChildren = childrenSelector.rules;
          if (children.first[k$children] != null && nextChildren != null) {
            await Future.wait(children.map((child) {
              child[k$origin] = newOriginInfo;
              return parseChildren(item: child).toList();
            }));
          }
        }
        // 判断是否拉平子节点(并终止获取)，否则追加到子节点下，
        if (childrenSelector.flat == true) {
          item.addAll(children.first);
          yield [item];
          break;
        } else {
          // 构建解析状态
          children
              .forEachIndexed((i, child) => child[k$origin] = newOriginInfo);
          // 判断是否继承父节点字段
          // if ($children.extended == true) {
          //   $children.rules?.map((index, selector) {
          //     if (selector.extended) {
          //       children['s']
          //     }
          //   });
          // extend && children.forEach((child, index) => (children[index] = Object.assign({}, item, child)))
          // }
          item[fieldChildren] != null
              ? item[fieldChildren]?.addAll(children)
              : (item[fieldChildren] = children);
          // print('YIDLE START =======================================');
          yield children;
          // print('YIDLE END =======================================');
        }
      } while (isMulitPage && keys.isNotEmpty);
    }
  }

  bool isEmpty(Object? o) {
    return o == null || o == "";
  }

  /// 通过Rule对象解析HTML，返回结果集
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
          TemplateParser.eachSelector(
              doc, exp.selector!, (result, index) => (content = result));
        }
        // 匹配正则内容
        final regexp = RegExp(exp.regex ?? '');
        final groups = List.of(regexp.allMatches(content));

        groups.forEachIndexed((i, item) {
          final match = item.groupCount > 0 ? item.group(1) : item.group(0);
          final value = TemplateParser.parseRegex(
              match ?? '', exp.capture, exp.replacement);
          props.add(value);
        });
        // 使用选择器匹配
      } else if (exp.selector != null) {
        TemplateParser.eachSelector(doc, exp.selector as String,
            (result, index) {
          // print('RRRR: $result, IIII: $index');
          // 执行最终替换，并添加到结果集
          final value =
              TemplateParser.parseRegex(result, exp.capture, exp.replacement);
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
    // 注入类型
    for (var item in resultSet) {
      item[k$type] = _site?.type ?? 'unknown';
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
        TemplateParser.parseUrl(indexUrl, page ?? _page, keywords ?? _keywords);
    // 发送请求
    final html = await _requestText(url, headers: _site?.headers);
    // 检查无效响应
    if (html.trim().isEmpty) return [];
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
    return _sectionName ?? (_keywords == null || _keywords!.trim().isEmpty ? 'home' : 'search');
  }
}
