# Glean Browser 扩展 V2 设计（万物皆可轻松收藏）

> 项目 slogan：**万物皆可轻松收藏**。
> 本文档规划 browser 端（`browser-extension/`）从 V1（划词/整页/WebDAV 快照）演进到
> 覆盖「链接 / 选区 / 图片 / 视频·音频 / 任意文件 / 整页离线」六类收藏，并回答两个关键问题：
> **WebDAV 能否承载这一切？私人网盘与 NAS 如何打通？**

---

## 1. 现状（V1）

- 划词右键收藏（纯文本，进收件箱条目）／右键整页收藏
- 右键「选分类后收藏…」弹窗（可选分类，来自云端快照）
- WebDAV 快照：`PUT <WebDAV>/glean/backup.json`（与 App 共用同一份 JSON）
- 本机 9797 端口 ping 桌面端即时同步
- 仅文本与引用，无媒体/离线能力

**App 端合并契约**：`sync_service.merge` 对 items 采用**白名单字段**（id/source/mediaPath/
originalUrl/sourceTitle/note/lang/status/createdAt），**未知字段（新增字段）安全忽略**——
插件可以在 items 上自由扩展字段，App 旧版本不受影响，新版本逐步消费。

---

## 2. V2 功能清单（六类收藏）

| # | 收藏类型 | 产物 | WebDAV 载体 | 优先级 |
|---|---|---|---|---|
| 1 | 网页链接 | 元数据（URL/标题/描述/封面引用） | `backup.json` 条目 | **V1 原型** |
| 2 | 选区（文本 + HTML 快照） | 文本 + `htmlClip` 字段 | `backup.json` 条目 | **V1 原型** |
| 3 | 图片 | 引用（必选）＋ 原图文件（可选） | `backup.json` 条目 + `/media/<id>.<ext>` | **V1 原型** |
| 4 | 视频 / 音频 | 引用 + 封面/元数据（流媒体降级） | `backup.json` 条目（+ 可下载文件） | V1.1 |
| 5 | 任意文件（PDF 等） | 原文件 + 元数据 | `/media/<id>.<ext>` | V1.1 |
| 6 | 整页离线 | 单文件 HTML（或 HTML+资源 zip） | `/media/<id>.html` 或 `.zip` | V2 |

**统一心智**：一切收藏 = **一条 items 元数据 + 可选 0~n 个媒体文件**。
WebDAV 只负责存储，任何"能变成文件或 JSON 条目"的内容都能收。

---

## 3. 抓取策略与约束（为什么不是所有内容都能"原样离线"）

浏览器扩展（MV3 service worker）抓取网页资源受三条硬约束：

1. **CORS / 跨域 fetch**：`host_permissions` 已含 `https://*/*`，多数静态资源可直接 fetch；
   但带鉴权、反爬、动态渲染（SPA）的内容拿不到。
2. **选区 HTML 需要 content script**：`contextMenus.onClicked` 只提供纯文本
   `selectionText`，不带 HTML —— 必须注入 content script 监听选区（见 §6.4）。
3. **流媒体不可直接下载**：m3u8 分段、防盗链、DRM 的音频视频抓不下来。

**降级原则（铁律）**：任何抓取失败 → 静默降级为「引用收藏」：
URL + 标题 + 描述 + 封面（`og:image`），保证"收藏动作永不失败、内容永远可回看"。
离线正文/媒体属于尽力而为的增强，不是承诺。

---

## 4. 数据契约（V2）

### 4.1 快照 JSON 演进

`<WebDAV>/glean/backup.json` 结构不变（`app: glean`, `rows.{collections,items,item_collections,item_tags}`），
items 条目扩展可选字段：

```jsonc
{
  "id": -4839125862001,
  "source": "image",            // browser | image | video | audio | file | clipboard | manual | word | quote | idea
  "originalUrl": "https://…/photo.jpg",
  "sourceTitle": "页面标题",
  "note": "用户备注或页面描述",
  // —— V2 新增（App 白名单忽略，旧版兼容）——
  "htmlClip": "<div>…选区 HTML…</div>",   // 选区快照（≤20KB）
  "mediaType": "image",          // image | video | audio | file | html
  "mediaPath": "/glean/media/-4839125862001.jpg", // WebDAV 相对路径（有文件时）
  "coverUrl": "https://…/og-cover.jpg"      // 封面引用（视频/网页）
}
```

### 4.2 媒体文件库

```
<WebDAV>/glean/
  backup.json          # 全量元数据快照（与 App 共用）
  media/
    <itemId>.<ext>     # 媒体文件，文件名 = 条目负 id，跨端幂等
```

- 目录惰性创建（MKCOL，已存在忽略）
- 文件用 Basic Auth 直接 PUT/GET；App 端按 `mediaPath` 按需下载/预览（V1.1+ 才消费）
- 删除语义：App 删除条目打墓碑；媒体文件由「孤儿清理」定期比对（V2）

### 4.3 同步流程

```
右键收藏 → 组装元数据（+可选抓取文件）
  → MKCOL /glean/media（首次）→ PUT 媒体文件 → PUT backup.json
  → ping 127.0.0.1:9797 → 桌面端静默合并
```

---

## 5. 私人网盘 / NAS 打通矩阵

WebDAV = 统一通道。**支持 WebDAV 的服务直接打通；不支持的走 API 适配或 alist 桥接。**

| 目标 | WebDAV 支持 | 打通方式 | 档位 |
|---|---|---|---|
| 坚果云 | ✅ 原生（国内最常用） | 直接配置 | **A 零开发** |
| 群晖 DSM / 威联通 QNAP | ✅ 原生 WebDAV Server | 直接配置 | A |
| 极空间 / 绿联 / 联想个人云 / openwrt 等 | ✅ 多原生支持 | 直接配置 | A |
| 阿里云盘 / 百度网盘 / 夸克 / 123 云盘 | ❌ 无 WebDAV | **alist** 桥接（用户自建） | B 桥接 |
| Dropbox / Google Drive / OneDrive | ❌（官方 API 为准） | alist 桥接；或按需开发原生适配器 | B → C |

**B 档（alist）**：开源免费、自托管、单二进制；把任意网盘挂载成一个 WebDAV 端点，
Glean 侧零改动。文档给出 3 分钟配置指南（下载 → 添加存储 → 开 WebDAV → 填进 Glean）。

**C 档（原生 API 适配器）**：有了用户量之后，为头部网盘（如百度/阿里）开发独立适配器，
此时抽象层从 `CloudDrive`（已有）扩展出 `MediaCloudDrive`（文件级读写 + 配额提示）。

**容量提示**：坚果云免费 1GB → 媒体默认「仅引用」，存文件前检查配额并明确提示；
NAS 无配额顾虑 → 推荐「引用 + 本地文件」双写。

---

## 6. 分期实施

### 6.1 V1 原型（本轮交付）

1. 右键**图片收藏**：`contextMenus` 图片菜单 → 引用必存 ＋ 原图尝试下载到 `/glean/media/`（失败静默引用兜底）
2. 选区**HTML 快照**：注入 content script 捕获选区，右键收藏时 `htmlClip` 随条目入库
3. **整页元数据增强**：网页收藏时 fetch 页面抓 `description` / `og:image` 补充元数据（失败静默）
4. 快照契约按 §4 扩展；全部字段向后兼容 App 白名单

### 6.2 V1.1

- 视频/音频引用收藏（封面 = og:image / 截图位）＋ 可直接下载的媒体直传
- PDF 等任意可下载文件的直传（下载前尺寸提示）
- App 端消费 `htmlClip` / `mediaPath`（条目预览）

### 6.3 V2

- 整页离线归档（抓取 HTML + 内联资源 → 单文件/zip；动态页自动降级引用）
- 媒体孤儿清理；配额监控；批量收藏（多图/多文件）
- 网盘适配器 C 档（按用户量决策）

### 6.4 技术要点（V1 原型）

- **选区 HTML**：`content_scripts`（`<all_urls>`，document_idle）监听 `selectionchange`，
  缓存最近选区 `{text, html}`（html 截断 20KB）；右键时 `tabs.sendMessage` 取走后清空。
  popup 手动输入场景 htmlClip 为空。
- **图片下载**：SW 内 `fetch(srcUrl)` → blob；`davPutBinary`（PUT Basic Auth）→
  `mediaPath`；任何异常吞掉，只留引用。
- **弹窗传参**：`pendingHtml` 与 `pendingText/pendingUrl/pendingTitle` 一起过 storage。

---

## 7. 与 App 端的关系

- App 端**零改动**可继续合并且安全忽略新字段（§1 白名单）
- 后续 App 版本按 `mediaType`/`htmlClip`/`mediaPath` 渲染：图片预览、选区 HTML 回看、媒体从 WebDAV 拉取
- 「离线网页」在 App 端回看需要内嵌浏览器或转 PDF 渲染（V2 单独设计，避免素材库式复杂度回潮）

---

## 8. 开发清单与验收（V1 原型）

- [ ] manifest：图片上下文菜单 + content_scripts 声明
- [ ] content.js：选区 {text, html} 捕获与消息应答
- [ ] snapshot.js：`appendItem` 支持 `htmlClip/mediaType/mediaPath/coverUrl`；`davPutBinary` + `ensureMediaDir`
- [ ] background.js：图片收藏流程（引用 → 下载 → 降级）；划词带 html；整页抓元数据
- [ ] popup.js/html：pendingHtml 透传
- [ ] `node --check` 全绿 + 手动用例清单（划词/图片/整页/降级路径）

**验收用例**：
1. 划词（含 HTML 页面）收藏 → 条目含 htmlClip，text 正常
2. 右键图片收藏 → 引用条目；webdav 可用时原图出现在 `/glean/media/`
3. 右键整页收藏 → 条目带 description/coverUrl（若页面有 og 标签）
4. WebDAV 不可用 → 全流程仍成功（降级引用），提示引导配置

---

## 9. 风险与边界

| 风险 | 对策 |
|---|---|
| 大媒体撑爆网盘配额 | 默认仅引用；存文件前查配额 + 明确提示；文档推荐 NAS/alist |
| 盗链/防盗链页面抓取失败 | 统一降级引用，收藏永不失败 |
| 版权内容离线保存 | 离线仅限「个人归档」用途声明；不提供全文托管 URL |
| 选区 HTML 注入 XSS 风险 | htmlClip 只在 App 端**只读渲染**（编辑器内隔离浏览），不做脚本执行 |
| 同步体积增长 | 全量 JSON 快照不变（媒体不入 JSON）；媒体按需拉取 |

---

## 10. 附：alist 快速接入指南（文档用）

```bash
# 1. 下载并解压（GitHub Releases，单二进制）
wget https://github.com/alist-org/alist/releases/latest/download/alist-linux-amd64.tar.gz
tar -xzf alist-linux-amd64.tar.gz && cd alist
# 2. 初始化（生成随机管理密码）
./alist admin random
# 3. 启动，浏览器打开 http://127.0.0.1:5244 → 管理面板
./alist server
# 4. 存储 → 添加（阿里云盘/百度网盘/OneDrive…，用你自己的账号授权）
# 5. 设置 → WebDAV → 启用（端口 5244 自带 WebDAV 端点 /dav）
# 6. Glean 设置里填：地址 http://127.0.0.1:5244/dav/ ，账号 admin，密码为第 2 步输出
```