import * as fs from 'fs/promises'
import { readFileSync } from 'fs'
/**
 *
 * @param dir
 * @returns
 */
async function listFiles(dir: string, exts: string[]): Promise<string[]> {
const files: string[] = []
const items = await fs.readdir(dir)
if (!dir.endsWith('/')) {
dir += '/'
}
for (const item of items) {
const path = `${dir}${item}`
const stat = await fs.stat(path)
if (stat.isDirectory()) {
files.push(...(await listFiles(path, exts)))
} else if (stat.isFile()) {
if (exts) {
for (const ext of exts) {
if (path.endsWith(ext)) {
files.push(path)
}
}
} else {
files.push(path)
}
}
}
return files
}

/**
 *
 * @param file
 * @returns
 */
// async function loadSite(file: string) {
//   return await fs.readFile(file)
// }
async function loadSite(file: string): Promise<Site | undefined> {
// return await fs.readFile(file)
try {
const site = JSON.parse((await fs.readFile(file)).toString()) as Site
// 注入默认请求头
setDefaultHeaders(site)
// 复用规则
reuseRules(site)
if (checkSite(site)) return site
} catch (e) {
console.warn(`JSON load failed: ${file}, Cause: ${(e as Error).message}`)
}
}

/**
 *
 * @param dir
 * @returns 解析目录下所有json为对象
 */
async function loadSites(dir: string): Promise<Site[]> {
const resultSet: Site[] = []
for (const file of await listFiles(dir, ['.json'])) {
const site = await loadSite(file)
site && resultSet.push(site)
}
return resultSet
}

function checkSite(site: Site) {
if (!(site && site.sections)) throw new Error('Empty site rules')
const values = Object.values(site.sections)
if (!(values && values.length && (values[0].rules || values[0].reuse))) throw new Error('Invalid site rules')
return site
}

function reuseRules(site: Site) {
if (site && site.sections) {
Object.entries(site.sections).forEach(([, section]) => {
if (section && section.reuse && site.sections[section.reuse]) {
section.rules = site.sections[section.reuse].rules
}
})
}
return site
}

/**
 * 设置默认的请求头
 * @param site
 */
function setDefaultHeaders(site: Site) {
if (!site) return
const headers = site.headers || {}
if (!headers.hasOwnProperty('User-Agent')) {
headers['User-Agnet'] = 'Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.94 Safari/537.36'
}
if (!headers.hasOwnProperty('Referer') && site.sections?.home?.index) {
const match = new RegExp('https?://.+?/').exec(site.sections.home.index)
if (match && match[0]) headers['Referer'] = match[0]
}
// if (headers.hasOwnProperty('Cookie')) {
//   headers['Cookie'] = headers['Cookie'] + 'SameSite=None; Secure;'
// }
site.headers = headers
}

export default {
setDefaultHeaders,
reuseRules,
checkSite,
loadSite,
loadSites,
}
