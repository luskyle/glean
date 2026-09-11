# Glean 收藏助手

> 把散落的好内容拾进来——单词、摘录、灵感、网页——划进收件箱，
> 归入你自己的分组，素材库链接本地媒体，数据全部留在你的设备上。

**官网**：<https://luskyle.github.io/glean/>　｜　[![官网](https://img.shields.io/badge/Glean-%E5%AE%98%E7%BD%91-2F6BFF?style=flat-square)](https://luskyle.github.io/glean/)
　[![License](https://img.shields.io/badge/License-Apache--2.0-blue.svg?style=flat-square)](LICENSE)

依据《拾忆App架构设计》《开发计划-分阶段功能路线》《技术调研-核心技术选型》
（vpub/docs/强化记忆）实现的 **收藏侧 MVP**：收件箱 + 剪贴板 + 素材库 + 云盘同步的一条收藏管道。

## 当前版本能力（v0.1.0）

- **三区布局**：收件箱 / 素材库 / 设置（宽屏桌面左侧栏 + IndexedStack 保状态；窄屏底部 Tab）
- **收藏管道**：手录收藏（备注 + 标签 + 分组）、剪贴板监听轻提示「有内容要收藏？」、网页摘录自动带出处（原文链接 + 来源页标题）
- **整理体系**：待归类 / 已收藏 / 已归档三段状态流转；库 → 子集两级分组（多对多、主库标记）
- **自动标注**：收藏内容自动识别语言（中文 / 日语 / 英语 / 其他）
- **本地素材库**：链接本地目录（**不导入媒体**），递归索引图片 / 视频，按目录分组 + 网格 / 列表视图 + 用途批注；素材仅本地使用
- **云盘同步**：WebDAV 通道，启动静默拉取合并 + 前台周期自动同步 + 本机写入方（浏览器插件等）实时通知；删除墓碑防复活
- **一键导出**：全量数据导出 zip（`glean_data.json` 机器可读 + `README.txt` 说明），数据随时带走
- **数据所有权**：全部数据本地存储（drift / SQLite），服务器零存储

## 技术栈（按技术调研选型）

Flutter（stable 线） · Riverpod（flutter_riverpod，无 codegen 简化初版） ·
drift（SQLite：items / collections / item_collections / item_tags / sync_deletions /
media_assets / media_folders）· shared_preferences（设置 KV）·
webdav_client（云盘同步）· file_picker + video_player（素材库）·
archive（导出 zip）· flutter_tts（朗读）· url_launcher（打开原文）· intl

## 工程结构（feature-first）

```
lib/
  core/       主题
  domain/     语言标注（纯 Dart，可单独单测）
  data/       drift 表/库、仓储（收藏/素材）、同步（WebDAV + 本地通知）、导出、设置、分析
  features/   home（外壳）/ inbox（收件箱）/ library（素材库）/ settings（设置）
  shared/     空态、状态徽标等通用组件
```

## 开发命令

```bash
# 环境（国内镜像已写入 ~/.bashrc）
export PATH="/media/luskyle/DATA/apps/flutter_dl/flutter/bin:$PATH"

# 依赖与代码生成（drift 表变更后重新生成 database.g.dart）
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# 静态检查与测试
flutter analyze
flutter test

# 运行（Linux 桌面需安装 clang；移动端在 Android Studio/Xcode 中运行）
flutter run
```

> 平台说明：本项目数据层使用 drift/SQLite（`dart:ffi`），**不支持 Web 编译**
> （路线图亦未包含 Web；V2 目标是 Windows/macOS 桌面端）。

## CI / CD（GitHub Actions）

- `.github/workflows/ci.yml`：main 分支 push / PR → `flutter analyze` + `flutter test`（质量门禁）
- `.github/workflows/release.yml`：推送 `v*` 标签（或手动 workflow_dispatch 指定 tag）→
  质量门禁 → 构建 Android APK / Linux tar.gz / iOS 未签名包 → 自动生成中文发布说明 →
  发布 GitHub Release（含全部产物；重复触发自动更新）
- 发布说明由 `scripts/gen_release_notes.sh` 从 git log 按 Conventional Commits 分组生成
- 官网（`docs/index.html`，纯静态、零构建依赖）：GitHub Pages 已启用
  （Settings → Pages → `Deploy from a branch` → `main` / `docs`）

发布前需在仓库配置（可选）：
- GitHub Secrets（Android 正式签名，缺省时自动回退 debug 签名发布）：
  `ANDROID_KEYSTORE`(base64 的 .jks) / `ANDROID_KEYSTORE_PASSWORD` / `ANDROID_KEY_ALIAS` / `ANDROID_KEY_PASSWORD`
- iOS 正式发布需 Apple 证书（当前产出未签名包）

```bash
# 出包：打标签即触发（版本号与 pubspec.version 保持一致）
git tag v0.1.0 && git push origin v0.1.0
```

## 测试

- `test/domain/analytics_service_test.dart`：本地事件埋点服务
- `test/data/sync_service_test.dart`：WebDAV 同步合并逻辑（含删除墓碑防复活）
- `test/live_webdav_test.dart`：真实 WebDAV 服务器集成冒烟（需配置环境变量）

## 开源协议

本项目采用 **Apache License 2.0** 开源，详见 [LICENSE](LICENSE)。
Contributions 即视为同意以相同协议授权。

## 与规划的差距（后续版本）

- OCR 拍照收藏 / 系统分享面板（V1.1）
- Anki 导入导出（V1.1）
- 浏览器划词收藏扩展（browser-extension，待接入）
- Windows / macOS 桌面端（V2）
- 删除墓碑 → 云端日志（V2，当前删除跨端同步靠本地墓碑）