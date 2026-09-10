# 内容插件机制设计

> 目标：一切符合机制的记忆内容都能导入训练；用户可自设计内容、应用提供玩法；
> 未来内容可在线分发（插件商店），下载后本地化训练。

## 核心抽象

一个**内容插件** = 玩法类型（`kind`）+ 内容单元列表（`items`）。

```dart
enum ContentKind { flashcard, quiz, cloze }   // 翻卡 / 单选 / 填空

class ContentPlugin {
  final String id;              // 唯一标识，如 'poetry.cn'
  final String name;            // 展示名
  final String description;
  final ContentKind kind;       // 玩法
  final List<ContentItem> items;
  final String locale;
}

sealed class ContentItem { }    // 按玩法分发
class FlashcardItem { front, back, hint? }                     // 翻卡
class QuizItem      { prompt, options[], answerIndex, explanation? }  // 单选
class ClozeItem     { title, subtitle?, lines[] }              // 填空（多行文本）
```

## 分层

```
lib/content/
  content_plugin.dart   模型：ContentKind / ContentItem / ContentPlugin
  builtin_plugins.dart  内置插件注册表 ContentRegistry（当前 4 个）
lib/features/study/
  content_player_screen.dart  统一播放器：按 kind 切换三套渲染
  study_screen.dart            学习 Tab：语言学习 + 内容插件列表
```

## 内置插件（当前）

| id              | 玩法 | 内容源 | 规模 |
|-----------------|------|-------|------|
| `poetry.cn`     | cloze | lib/assets/poetry/poems.json | 32 首 |
| `words.en.daily`| flashcard | lib/assets/content/en-daily.json | 50 词 |
| `words.ja.jlpt` | flashcard | lib/assets/dictionary/jlpt.json（N5，动态取） | ≤60 词 |
| `quiz.cn.general`| quiz | lib/assets/content/general-quiz.json | 20 题 |

## 新增内容插件的两种方式

1. **纯数据插件**：在 `lib/assets/content/` 放 JSON，`ContentRegistry` 加一个加载器。
   翻卡：`{"entries":[{"front":"…","back":"…"}]}`
   单选：`{"items":[{"prompt":"…","options":[…],"answer":2,"explanation":"…"}]}`
   填空：`{"items":[{"title":"…","subtitle":"…","lines":[…]}]}`（播放器按策略自动挖空）
2. **代码插件**：实现 `ContentPlugin` 由代码动态生成 items（如 jlpt 从词库截取）。

## 未来：在线插件商店

- 插件清单改为从网络拉取（`List<ContentPluginManifest>`），内容按需下载到本地缓存
- 玩法渲染（ContentPlayerScreen）与数据结构不变，仅新增 `RemoteContentRegistry`
- 用户自制内容：同一套 JSON 格式导出/导入即可复用全部玩法
- 插件 id 全局唯一，本地已安装列表持久化（如 shared_preferences / drift）

## 玩法说明

- **翻卡**：先看正面 → 点卡翻面 → 自评（忘了 0 / 模糊 1 / 记得 2），计分
- **单选**：四选一 → 即时标对错 + 解析 → 下一题
- **填空**：多行文本随机挖空（短句不挖、空位不重叠）→ 输入 → 检查（绿/红 + 正确答案）

> 注：当前播放器答题结果不自动进入 SRS 复习队列；后续可提供「加入记忆库」
> 让学习类插件与间隔复习打通。