# Glean 收藏助手

> **万物皆可轻松收藏**——网页、链接、选区、图片、视频、音频、文件、整页离线，
> 一次右键全部收下；数据走你自己的云盘，服务器零存储。

**官网**：<https://luskyle.github.io/glean/>　｜　[![官网](https://img.shields.io/badge/Glean-%E5%AE%98%E7%BD%91-2F6BFF?style=flat-square)](https://luskyle.github.io/glean/)
　[![License](https://img.shields.io/badge/License-Apache--2.0-blue.svg?style=flat-square)](LICENSE)

## 当前能力（v0.1.0）

### 收藏（本地优先，一条管道全收下）

- **手录收藏**：一个输入框收藏，语言自动标注、随时补分组与标签
- **浏览器扩展（六类收藏）**：
  - 划词收藏（含选区 HTML 快照）
  - 网页链接 / 整页元数据（标题 + 描述 + og 封面）
  - 图片（引用 + 原图直传媒体库）/ 视频·音频 / PDF 等任意文件
  - **整页离线**：抓取页面生成单文件 HTML（静态资源 base64 内联，失败自动降级引用）
  - 批量收藏页面图片（≤30 张）。
- 超体积（50/100MB）自动弹窗询问「收藏源文件 / 仅收藏链接」
- 分类（库/子集两级）、标签、全文搜索、语言筛选

### 云盘同步（文本元数据 + 可选媒体文件）

支持 **7 种通道**，数据只进你自己的云盘：

| 通道 | 方式 |
|---|---|
| iCloud Drive | iOS 原生 |
| WebDAV | 坚果云 / 群晖·威联通等 NAS / alist 桥接（任意网盘） |
| 百度网盘 / 阿里云盘 / OneDrive / Dropbox / Google Drive | 原生 API 适配器（OAuth + 自动刷新，私有目录权限） |

- 启动静默合并 + 前台周期同步 + 浏览器插件本机写入即时通知
- 删除墓碑防复活；**打开媒体/离线页面**（从云盘下载到本地用系统应用打开）
- **云盘媒体维护**：统计文件与体积、一键清理孤儿文件
- 快照契约向后兼容（App 白名单合并，插件新字段安全忽略）

## 技术栈

Flutter（stable 线） · Riverpod（flutter_riverpod） ·
drift（SQLite：items/collections/item_collections/item_tags/sync_deletions）·
shared_preferences · http + webdav_client（云盘通道）·
flutter_widget_from_html_core（选区快照只读渲染，不执行脚本）·
archive（导出 zip）· url_launcher · path_provider

## 工程结构（feature-first）

```
lib/
  core/       主题
  domain/     语言标注（纯 Dart）
  data/
    database/   drift 表/库（schema v6）
    repositories/  收藏仓储
    sync/       同步服务、快照、云盘抽象
      netdisk/   网盘适配器家族（百度/阿里/OneDrive/Dropbox/Google Drive + 公共令牌层）
    export/     一键导出 zip（JSON 机器可读）
    settings/   设置 KV
  features/   home（外壳）/ inbox（收藏列表）/ settings
  shared/     空态、语言徽标
browser-extension/   六类收藏扩展（content script + service worker）
docs/              设计文档（浏览器扩展 V2 规划、架构与网盘矩阵）
```

## 开发命令

```bash
# 环境（国内镜像已写入 ~/.bashrc）
export PATH="/media/luskyle/DATA/apps/flutter_dl/flutter/bin:$PATH"

# 依赖与代码生成（drift 表变更后重新生成 database.g.dart）
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# 静态检查与测试（34 项：同步/快照/网盘协议/媒体接口）
flutter analyze
flutter test

# 运行（Linux 桌面；本机 libstdc++ 修补已内置于 CMakeLists）
flutter run -d linux
```

> 平台说明：数据层使用 drift/SQLite（`dart:ffi`），不支持 Web 编译；目标 Windows/macOS 桌面端（V2）。

## 浏览器扩展

```
browser-extension/（Chrome / Edge，Manifest V3）
```
加载方式：扩展管理页 → 开发者模式 → 加载已解压的扩展程序 → 选 `browser-extension/`。
配置 WebDAV 后右键即收，桌面端 9797 端口即时同步。V2 设计与网盘矩阵见
[docs/browser-extension-v2.md](docs/browser-extension-v2.md)。

## CI / CD（GitHub Actions）

- `ci.yml`：main push / PR → `flutter analyze` + `flutter test`
- `release.yml`：推送 `v*` 标签 → 质量门禁 → Android APK / Linux tar.gz / iOS 未签名包 →
  中文发布说明 → GitHub Release
- 官网 `docs/index.html`（纯静态）：GitHub Pages 已启用（main 分支 /docs 部署）

## 开源协议

Apache License 2.0，详见 [LICENSE](LICENSE)。Contributions 视为同意以相同协议授权。

## 路线图

- V1.1+：离线页内嵌阅读器、媒体配额监控、批量下载收藏
- V2：Windows/macOS 桌面端、Anki 导入导出、更多网盘适配（按用户反馈）