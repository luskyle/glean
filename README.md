# 拾忆（Shiyi）

> 把你想记住的任何东西——单词、摘抄、灵感、考纲——划进收件箱，
> App 用间隔重复（SM-2）自动安排复习，直到你真正记住。

依据《拾忆App架构设计》《开发计划-分阶段功能路线》《技术调研-核心技术选型》
（vpub/docs/强化记忆）实现的 **MVP 初版**（对应里程碑 M0 ~ 阶段 1 核心闭环）。

## 当前版本能力（v0.1.0）

- **三 Tab 常驻**：收件箱 / 复习（默认落点）/ 记忆库，IndexedStack 保状态
- **收藏管道**：手录收藏（词条/语录/灵感 + 标签 + 分组）、剪贴板监听轻提示
- **成卡**：词条自动命中内置离线词库补释义/读音（本地优先原则），全部可编辑
- **复习闭环**：闪卡先猜后看（翻转动画）、三键评级（忘了/模糊/记得）→ SM-2 调度
- **数据证明**：遗忘曲线（fl_chart 周视图，个人正确率 vs 理论基线）、掌握率/积压统计
- **记忆库**：全文搜索、语言/状态筛选、分组视图 + 分组掌握率
- **免费额度**：非 Pro 每日 30 次复习、记忆库 100 张（超限提示不打断复习）
- **数据所有权**：全部数据本地存储（drift/SQLite），一键导出 JSON

## 技术栈（按技术调研选型）

Flutter（stable 线） · Riverpod（flutter_riverpod，无 codegen 简化初版） ·
drift（SQLite，7 张表：words/cards/items/review_log/collections/item_collections/item_tags）·
fl_chart · shared_preferences（设置 KV）

## 工程结构（feature-first）

```
lib/
  core/       主题
  domain/     SM-2 引擎、语言识别（纯 Dart，无 Flutter 依赖，可单独单测）
  data/       drift 表/库、仓储（收藏/复习/统计）、离线词库、设置、导出
  features/   inbox（收件箱）/ review（复习+曲线）/ library（记忆库）/ settings
  shared/     空态、徽标等通用组件
```

## 开发命令

```bash
# 环境（国内镜像已写入 ~/.bashrc）
export PATH="/media/luskyle/DATA/apps/flutter_dl/flutter/bin:$PATH"

# 依赖与代码生成（drift 表变更后重新生成 database.g.dart）
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# 静态检查与测试（M0 验收：analyze 零问题 + test 全绿）
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

发布前需在仓库配置（可选）：
- GitHub Secrets（Android 正式签名，缺省时自动回退 debug 签名发布）：
  `ANDROID_KEYSTORE`(base64 的 .jks) / `ANDROID_KEYSTORE_PASSWORD` / `ANDROID_KEY_ALIAS` / `ANDROID_KEY_PASSWORD`
- iOS 正式发布需 Apple 证书（当前产出未签名包）

```bash
# 出包：打标签即触发（版本号与 pubspec.version 保持一致）
git tag v0.2.0 && git push origin v0.2.0
```

## 测试

- `test/domain/sm2_test.dart`：SM-2 引擎 20+ 用例（忘记/模糊/记得、间隔边界、
  重学路径、EF 钳制 1.3~3.0、到期判定、掌握度投影、长周期稳定性）
- `test/domain/language_test.dart`：多语言自动标注启发式
- `test/widget/app_smoke_test.dart`：三 Tab 切换与空态
- `test/widget/review_flow_test.dart`：复习闭环（翻卡→评级→落库）、重学路径、状态投影

## 与规划的差距（后续版本）

- SM-2 → FSRS（review_log 已保留完整字段，≥4 周数据后可切换）
- OCR / 分享面板 / Anki 导入导出（V1.1）
- 云盘同步 B 档、云端日志 C 档（V1.2 / V2）
- 内购接入（阶段 2，当前订阅墙为方案占位）
- 词库管线：Python 清洗 JLPT/COCA → JSON 导入（当前为内置微型样例词库）