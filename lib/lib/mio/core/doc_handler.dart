import 'dart:html';

import 'package:comic_nyaa/lib/mio/core/rule_loader.dart';
import 'package:html/parser.dart';

import '../model/site_.dart';

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
final REG_SELECTOR_TEMPLATE = RegExp(r"\$\((.*?)\)\.(\w+?)\((.*?)\)/");

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
  Future<List<T>> parseSite([bool isParseChildren = false]) async {
    return await this.parseSection(this.getCurrentSection(), isParseChildren);
  }
/// 解析Section对象，返回结果集
/// @param {Section} section 站点板块
/// @param {Number} deep 解析深度
/// @return {Promise<<T extends Meta>[]>}
  Future<List<T>> parseSection(Section section, bool isParseChildren) async {
if (site == null) throw Exception('site cannot be empty!');
// 复用规则，现在已经在SiteLoader中处理
// if (section.reuse) {
//   section.rules = this.site.sections[section.reuse].rules
// }
const result = await this.parseRules(section.index, section.rules);
result.forEach((item) => {
item.$section = section;
item.$site = this.site;
})
if (isParseChildren && section.rules.$children) {
await this.parseChildrenOfList(result, section.rules);
}
return result
}
  Future<void> parseChildrenOfList(List<T> list, Rules rules) async {
    Future.wait(list.map((item) => this.parseChildrenConcurrency(item, rules)))
// await Promise.allSettled(list.map((item) => this.parseChildrenConcurrency(item, rules)))
}
/// 解析Children，自动检测末尾，自动继承父级，自动拉平单项子级
/// @param {*} item
/// @param {*} rules
/// @return {Promise<T extends Meta>}
  Future<T> parseChildrenConcurrency(T item, Rules rules, [bool extend = true]) async {
if (item.$children != null && rules.$children != null) {
List<T> histroy = List.empty();
int page = 0;
// do {
const children = await this.parseRules(item.$children, rules.$children.rules, page++);
// if (children && histroy && children.length && histroy.length && children.length === histroy.length && this.objectEquals(children[0], histroy[0])) break
// if (children != null && children.length > 0 && histroy.isNotEmpty && children.length == histroy.length && this.objectEquals(children[0], histroy[0])) break;
//
// histroy = JSON.parse(JSON.stringify(children));
if (children  && children.length) {
// 解析下级子节点
if (children[0].$children) {
await Future.wait(children.map((child) => this.parseChildrenConcurrency(child, rules.$children.rules)));
}
// 判断是否拉平子节点，否则追加到子节点下
if (rules.$children?.flat != null && rules.$children?.flat == true) {
// Object.assign(item, children[0]);
break;
} else {
// 判断并继承父节点字段
// extend && children.forEach((child, index) => (children[index] = Object.assign({}, item, child)))
item.children != null ? item.children?.addAll(children) : (item.children = children);
break;
}
}
// } while (histroy && histroy.length);
}
return item;
}

/// 解析Rule对象，返回结果集
/// @param {Number} page 页码
/// @param {Number} keywords 关键字
/// @returns {Promise<<T extends Meta>[]>}
  Future<List<T>> parseRules(String _url, Rules rule, [int page = 1, String keywords = '']) async  {
if (rule == null) return List.empty();
// 生成URL
    final url = this.replaceUrlTemplate(_url, page, keywords);
// 发送请求
    final html = await this.requestText(url, { headers: this.site?.headers });
// 检查无效响应
if (!html) return [];
// 加载文档
final $ = parse(html); //cheerio.load(html);
    final List<T> resultSet = List.empty();
// 遍历选择器集
for (const k of Object.keys(rule)) {
const exp = rule[k];
if (exp.regex) {
let context = '';
// 匹配选择器内容
if (exp.selector) {
// 此处的选择器只应选择一个元素，否则result会被刷新为最后一个
this.selectEach($, exp.selector, (result) => (context = result));
} else {
context = $('html').toString();
}
// 匹配正则内容
const regexp = new RegExp(exp.regex, 'g')
let res: RegExpExecArray | null
for (let i = 0; (res = regexp.exec(context)) != null; i++) {
// 以第一个组为匹配值
if (res[1]) {
// 执行最终替换，并添加到结果集
resultSet[i] || resultSet.push({} as T)
resultSet[i][k] = this.replaceRegex(res[1], exp.capture, exp.replacement)
}
}
} else if (exp.selector) {
this.selectEach($, exp.selector, (result, index) => {
// 执行最终替换，并添加到结果集
resultSet[index] || resultSet.push({} as T)
resultSet[index][k] = this.replaceRegex(result, exp.capture, exp.replacement)
})
}
}
return resultSet
}

/**
 * 请求文档内容，默认使用fetch发送请求，自动注入请求头
 * @param {String} url 链接
 * @param {Object} options 操作
 * @returns {Promise<String>} 响应文本
 */
async requestText(url: string, options: RequestOptions): Promise<string | undefined> {
// 如果已有传入请求，则使用传入的
// if (this.request) {
//   return await this.request(url, options || {})
// }
// const resp = await fetch(url, options)
// if (resp.ok) {
//   return await resp.text()
// }
// return ''
return this.request ? this.request(url, options) : config.request(url, options)
}

/**
 * 获取当前板块
 * @returns {Section}
 */
getCurrentSection(): Section {
if (!this.site) throw Error('site cannot be empty!')
const section = this.keywords ? this.site.sections.search : this.site.sections.home
// 复用规则
// if (section.reuse) {
//   section.rules = this.site.sections[section.reuse].rules
// }
return section
}

/**
 * 遍历选择器
 * @param {cheerio.CheerioAPI} $ 文档上下文
 * @param {string} selector 选择器
 * @param {function} each
 */
selectEach($: cheerio.CheerioAPI, selector: string, each: (content: string, index: number) => void) {
const match = REG_SELECTOR_TEMPLATE.exec(selector)
if (!match) return
const s = {
select: match[1],
func: match[2],
attr: match[3],
}
// 遍历元素集
$(s.select).each((index, el) => {
let result = ''
switch (s.func) {
case 'attr':
//@ts-ignore
result = el.attribs[s.attr]
// result = el.attr[s.attr]
break
case 'text':
result = $(el).text()
break
case 'html':
result = $(el).html() || ''
break
}
each(result, index)
})
}
/**
 * 替换正则式
 * @param {String} text 文本
 * @param {String} capture 截取式
 * @param {String} replacement 替换式
 * @returns {String} 结果
 */
replaceRegex(text: string, capture?: string, replacement?: string): string {
if (!text) return replacement || ''
if (!capture) return text
if (!replacement) {
const m = new RegExp(capture).exec(text)
return m && m[0] ? m[0] : text
}
const result = new RegExp(capture).exec(text)
result && result.forEach((item, index) => (replacement = replacement?.replace(new RegExp('\\$' + index, 'g'), item)))
return replacement
}

/**
 * 替换URL模板
 * @param {String} template 模板
 * @param {Number} page 当前页码
 * @param {String} keywords 关键字
 * @returns {String} 真实URL
 */
replaceUrlTemplate(template: string, page: number, keywords?: string): string {
const pageMatch = REG_PAGE_TEMPLATE.exec(template)
const keywordMatch = REG_KEYWORD_TEMPLATE.exec(template)
// 获取默认keywords
const _keywords = keywordMatch && keywordMatch[1] ? keywordMatch[1] : ''
// 计算真实分页值
page = pageMatch && pageMatch[1] ? page + parseInt(pageMatch[1]) : page
page = pageMatch && pageMatch[2] ? page * parseInt(pageMatch[2]) : page
// 生成真实URL
return template.replace(REG_PAGE_MATCH, page.toString()).replace(REG_KEYWORD_MATCH, keywords || _keywords)
}
/**
 * 对象比较
 * see https://stackoverflow.com/a/6713782
 * @author Jean Vincent
 * @param {*} x
 * @param {*} y
 * @param {*} deep deep equals
 * @returns
 */
objectEquals(x: any, y: any, deep: boolean = false): boolean {
if (x === y) return true
// if both x and y are null or undefined and exactly the same
if (!(x instanceof Object) || !(y instanceof Object)) return false
// if they are not strictly equal, they both need to be Objects
if (x.constructor !== y.constructor) return false
// they must have the exact same prototype chain, the closest we can do is
// test there constructor.
for (var p in x) {
if (!x.hasOwnProperty(p)) continue
// other properties were tested using x.constructor === y.constructor
if (!y.hasOwnProperty(p)) return false
// allows to compare x[ p ] and y[ p ] when set to undefined
if (x[p] === y[p]) continue
// if they have the same strict value or identity then they are equal
if (typeof x[p] !== 'object') return false
// Numbers, Strings, Functions, Booleans must be strictly equal
if (deep && !this.objectEquals(x[p], y[p], deep)) return false
// Objects and Arrays must be tested recursively
}
for (p in y) if (y.hasOwnProperty(p) && !x.hasOwnProperty(p)) return false
// allows x[ p ] to be set to undefined
return true
}
}
}
// export default class Kumoko<T extends Meta> {
//   // 当前抓取规则
//   site: Site | undefined
//   // 当前分页值
//   page: number = 1
//   // 搜索关键字
//   keywords: string | undefined = undefined
//   //
//   request: ((url: string, options: RequestOptions) => Promise<string | undefined>) | undefined = undefined
//
//   /**
//    * 通过配置构造一个抓取对象
//    * @param {Site} site 规则
//    */
//   constructor(site: Site) {
//   this.site = site
//   }
//   setSite(site: Site): Kumoko<T> {
//   this.site = site
//   return this
//   }
//   setPage(page: number): Kumoko<T> {
//   this.page = page
//   return this
//   }
//   setKeywords(keywords: string): Kumoko<T> {
//   this.keywords = keywords
//   return this
//   }
//   setRequest(request: (url: string, options: RequestOptions) => Promise<string | undefined>): Kumoko<T> {
//   // this.request = request
//   this.request = request
//   return this
// }
// /**
//  * 解析Site对象，返回结果集
//  * @returns {Promise<<T extends Meta>[]>}
//  */
// async parseSite(isParseChildren = false): Promise<T[]> {
// return await this.parseSection(this.getCurrentSection(), isParseChildren)
// }
//
// /**
//  * 解析Section对象，返回结果集
//  * @param {Section} section 站点板块
//  * @param {Number} deep 解析深度
//  * @return {Promise<<T extends Meta>[]>}
//  */
// async parseSection(section: Section, isParseChildren = false): Promise<T[]> {
// if (!this.site) throw new Error('site cannot be empty!')
// // 复用规则，现在已经在SiteLoader中处理
// // if (section.reuse) {
// //   section.rules = this.site.sections[section.reuse].rules
// // }
// const result = await this.parseRules(section.index, section.rules)
// result.forEach((item) => {
// item.$section = section
// item.$site = this.site
// })
// if (isParseChildren && section.rules.$children) {
// await this.parseChildrenOfList(result, section.rules)
// }
// return result
// }
// async parseChildrenOfList(list: T[], rules: Rules): Promise<void> {
// await Promise.allSettled(list.map((item) => this.parseChildrenConcurrency(item, rules)))
// }
// /**
//  * 解析Children，自动检测末尾，自动继承父级，自动拉平单项子级
//  * @param {*} item
//  * @param {*} rules
//  * @return {Promise<T extends Meta>}
//  */
// async parseChildrenConcurrency(item: T, rules: Rules, extend = true): Promise<T> {
// if (item.$children && rules.$children) {
// let histroy: T[] = []
// let page = 0
// do {
// const children = await this.parseRules(item.$children, rules.$children.rules, page++)
// if (children && histroy && children.length && histroy.length && children.length === histroy.length && this.objectEquals(children[0], histroy[0])) break
// histroy = JSON.parse(JSON.stringify(children))
// if (children && children.length) {
// // 解析下级子节点
// if (children[0].$children) {
// await Promise.allSettled(children.map((child) => this.parseChildrenConcurrency(child, rules.$children.rules)))
// }
// // 判断是否拉平子节点，否则追加到子节点下
// if (rules.$children.flat) {
// Object.assign(item, children[0])
// break
// } else {
// // 判断并继承父节点字段
// // extend && children.forEach((child, index) => (children[index] = Object.assign({}, item, child)))
// item.children ? item.children.push(...children) : (item.children = children)
// break
// }
// }
// } while (histroy && histroy.length)
// }
// return item
// }
//
// /**
//  * 解析Rule对象，返回结果集
//  * @param {Number} page 页码
//  * @param {Number} keywords 关键字
//  * @returns {Promise<<T extends Meta>[]>}
//  */
// async parseRules(_url: string, rule: Rules, page: number = this.page, keywords: string | undefined = this.keywords): Promise<T[]> {
// if (!rule) return []
// // 生成URL
// const url = this.replaceUrlTemplate(_url, page, keywords)
// // 发送请求
// const html = await this.requestText(url, { headers: this.site?.headers })
// // 检查无效响应
// if (!html) return []
// // 加载文档
// const $ = cheerio.load(html)
// const resultSet: T[] = []
// // 遍历选择器集
// for (const k of Object.keys(rule)) {
// const exp = rule[k]
// if (exp.regex) {
// let context = ''
// // 匹配选择器内容
// if (exp.selector) {
// // 此处的选择器只应选择一个元素，否则result会被刷新为最后一个
// this.selectEach($, exp.selector, (result) => (context = result))
// } else {
// context = $('html').toString()
// }
// // 匹配正则内容
// const regexp = new RegExp(exp.regex, 'g')
// let res: RegExpExecArray | null
// for (let i = 0; (res = regexp.exec(context)) != null; i++) {
// // 以第一个组为匹配值
// if (res[1]) {
// // 执行最终替换，并添加到结果集
// resultSet[i] || resultSet.push({} as T)
// resultSet[i][k] = this.replaceRegex(res[1], exp.capture, exp.replacement)
// }
// }
// } else if (exp.selector) {
// this.selectEach($, exp.selector, (result, index) => {
// // 执行最终替换，并添加到结果集
// resultSet[index] || resultSet.push({} as T)
// resultSet[index][k] = this.replaceRegex(result, exp.capture, exp.replacement)
// })
// }
// }
// return resultSet
// }
//
// /**
//  * 请求文档内容，默认使用fetch发送请求，自动注入请求头
//  * @param {String} url 链接
//  * @param {Object} options 操作
//  * @returns {Promise<String>} 响应文本
//  */
// async requestText(url: string, options: RequestOptions): Promise<string | undefined> {
// // 如果已有传入请求，则使用传入的
// // if (this.request) {
// //   return await this.request(url, options || {})
// // }
// // const resp = await fetch(url, options)
// // if (resp.ok) {
// //   return await resp.text()
// // }
// // return ''
// return this.request ? this.request(url, options) : config.request(url, options)
// }
//
// /**
//  * 获取当前板块
//  * @returns {Section}
//  */
// getCurrentSection(): Section {
// if (!this.site) throw Error('site cannot be empty!')
// const section = this.keywords ? this.site.sections.search : this.site.sections.home
// // 复用规则
// // if (section.reuse) {
// //   section.rules = this.site.sections[section.reuse].rules
// // }
// return section
// }
//
// /**
//  * 遍历选择器
//  * @param {cheerio.CheerioAPI} $ 文档上下文
//  * @param {string} selector 选择器
//  * @param {function} each
//  */
// selectEach($: cheerio.CheerioAPI, selector: string, each: (content: string, index: number) => void) {
// const match = REG_SELECTOR_TEMPLATE.exec(selector)
// if (!match) return
// const s = {
// select: match[1],
// func: match[2],
// attr: match[3],
// }
// // 遍历元素集
// $(s.select).each((index, el) => {
// let result = ''
// switch (s.func) {
// case 'attr':
// //@ts-ignore
// result = el.attribs[s.attr]
// // result = el.attr[s.attr]
// break
// case 'text':
// result = $(el).text()
// break
// case 'html':
// result = $(el).html() || ''
// break
// }
// each(result, index)
// })
// }
// /**
//  * 替换正则式
//  * @param {String} text 文本
//  * @param {String} capture 截取式
//  * @param {String} replacement 替换式
//  * @returns {String} 结果
//  */
// replaceRegex(text: string, capture?: string, replacement?: string): string {
// if (!text) return replacement || ''
// if (!capture) return text
// if (!replacement) {
// const m = new RegExp(capture).exec(text)
// return m && m[0] ? m[0] : text
// }
// const result = new RegExp(capture).exec(text)
// result && result.forEach((item, index) => (replacement = replacement?.replace(new RegExp('\\$' + index, 'g'), item)))
// return replacement
// }
//
// /**
//  * 替换URL模板
//  * @param {String} template 模板
//  * @param {Number} page 当前页码
//  * @param {String} keywords 关键字
//  * @returns {String} 真实URL
//  */
// replaceUrlTemplate(template: string, page: number, keywords?: string): string {
// const pageMatch = REG_PAGE_TEMPLATE.exec(template)
// const keywordMatch = REG_KEYWORD_TEMPLATE.exec(template)
// // 获取默认keywords
// const _keywords = keywordMatch && keywordMatch[1] ? keywordMatch[1] : ''
// // 计算真实分页值
// page = pageMatch && pageMatch[1] ? page + parseInt(pageMatch[1]) : page
// page = pageMatch && pageMatch[2] ? page * parseInt(pageMatch[2]) : page
// // 生成真实URL
// return template.replace(REG_PAGE_MATCH, page.toString()).replace(REG_KEYWORD_MATCH, keywords || _keywords)
// }
// /**
//  * 对象比较
//  * see https://stackoverflow.com/a/6713782
//  * @author Jean Vincent
//  * @param {*} x
//  * @param {*} y
//  * @param {*} deep deep equals
//  * @returns
//  */
// objectEquals(x: any, y: any, deep: boolean = false): boolean {
// if (x === y) return true
// // if both x and y are null or undefined and exactly the same
// if (!(x instanceof Object) || !(y instanceof Object)) return false
// // if they are not strictly equal, they both need to be Objects
// if (x.constructor !== y.constructor) return false
// // they must have the exact same prototype chain, the closest we can do is
// // test there constructor.
// for (var p in x) {
// if (!x.hasOwnProperty(p)) continue
// // other properties were tested using x.constructor === y.constructor
// if (!y.hasOwnProperty(p)) return false
// // allows to compare x[ p ] and y[ p ] when set to undefined
// if (x[p] === y[p]) continue
// // if they have the same strict value or identity then they are equal
// if (typeof x[p] !== 'object') return false
// // Numbers, Strings, Functions, Booleans must be strictly equal
// if (deep && !this.objectEquals(x[p], y[p], deep)) return false
// // Objects and Arrays must be tested recursively
// }
// for (p in y) if (y.hasOwnProperty(p) && !x.hasOwnProperty(p)) return false
// // allows x[ p ] to be set to undefined
// return true
// }
// }
//
// export {
// Kumoko,
// config
// }