import 'package:drift/drift.dart';

/// 词条（官方词库，多模态素材复用；MVP 内置小词库，后续由 Python 词库管线导入）
@DataClassName('WordRow')
class Words extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get lang => text()();
  TextColumn get headword => text()();
  TextColumn get reading => text().nullable()();
  TextColumn get ipa => text().nullable()();
  TextColumn get audioFile => text().nullable()();
  TextColumn get level => text().nullable()();
  TextColumn get tags => text().nullable()();
}

/// 卡片（SRS 对象，复习引擎的调度单元）
@DataClassName('CardRow')
class Cards extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get wordId => integer()
      .nullable()
      .references(Words, #id, onDelete: KeyAction.setNull)();

  /// 卡种：word | quote | idea | clip
  TextColumn get kind => text().withDefault(const Constant('word'))();
  TextColumn get prompt => text()();
  TextColumn get answer => text()();
  TextColumn get audioFile => text().nullable()();

  /// 语言标签（自动标注，复习过滤用）
  TextColumn get lang => text().nullable()();

  /// 冗余标签（搜索增强）
  TextColumn get tags => text().nullable()();

  // ---- SRS 调度状态（SM-2）----
  IntColumn get repetitions => integer().withDefault(const Constant(0))();
  RealColumn get easeFactor => real().withDefault(const Constant(2.5))();
  IntColumn get intervalDays => integer().withDefault(const Constant(0))();
  DateTimeColumn get dueAt => dateTime()();
  DateTimeColumn get lastReviewedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

/// 收藏条目（工具版核心：收藏管道的一等公民）
@DataClassName('ItemRow')
class Items extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 成卡后可空（未成卡 = 待归类）
  IntColumn get cardId => integer()
      .nullable()
      .references(Cards, #id, onDelete: KeyAction.setNull)();

  /// 来源：share | clipboard | photo | manual | anki_import
  TextColumn get source => text().withDefault(const Constant('manual'))();
  TextColumn get mediaPath => text().nullable()();
  TextColumn get originalUrl => text().nullable()();

  /// 链接的本地素材（素材库引用，不随云同步；仅本地使用）
  IntColumn get mediaAssetId => integer().nullable()();

  /// 网页摘录来源页标题（Phase 1：划词收藏自动带出处）
  TextColumn get sourceTitle => text().nullable()();

  /// 用户备注（为什么收）
  TextColumn get note => text().nullable()();

  /// 语言标签（自动标注）
  TextColumn get lang => text().nullable()();

  /// 状态 = SRS + review_log 的投影缓存：inbox | learning | mastered | cold
  TextColumn get status => text().withDefault(const Constant('inbox'))();
  DateTimeColumn get createdAt => dateTime()();
}

/// 复习日志（append-only，唯一事实来源之一；投影与统计全部从这里派生）
@DataClassName('ReviewLogRow')
class ReviewLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cardId =>
      integer().references(Cards, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get reviewedAt => dateTime()();
  IntColumn get quality => integer()();
  IntColumn get intervalDays => integer()();
  RealColumn get easeFactor => real()();

  /// learning | review | relearning（记录复习时所处阶段）
  TextColumn get state => text()();

  /// review | exam | import（来源）
  TextColumn get source => text().withDefault(const Constant('review'))();
}

/// 库 / 子集（三层分类：库 Collection → 子集 Series → 条目 Item，MVP 实现两层）
@DataClassName('CollectionRow')
class Collections extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get parentId => integer().nullable().references(Collections, #id)();
  IntColumn get ownerId => integer().nullable()();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
}

/// 条目-库 多对多（主库标记决定默认归属视图）
@DataClassName('ItemCollectionRow')
class ItemCollections extends Table {
  IntColumn get itemId =>
      integer().references(Items, #id, onDelete: KeyAction.cascade)();
  IntColumn get collectionId =>
      integer().references(Collections, #id, onDelete: KeyAction.cascade)();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {itemId, collectionId};
}

/// 条目标签（多标签交叉，搜索增强）
@DataClassName('ItemTagRow')
class ItemTags extends Table {
  IntColumn get itemId =>
      integer().references(Items, #id, onDelete: KeyAction.cascade)();
  TextColumn get tag => text()();

  @override
  Set<Column<Object>> get primaryKey => {itemId, tag};
}

/// 删除墓碑（同步用）：记录被用户删除的实体 id，防止"拉取合并"把它复活。
@DataClassName('SyncDeletionRow')
class SyncDeletions extends Table {
  TextColumn get entityTable => text()();
  IntColumn get entityId => integer()();
  DateTimeColumn get deletedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {entityTable, entityId};
}

/// 本地素材库（记忆教练：链接不导入）：
/// 仅索引本地文件路径，绝不复制媒体；素材不参与云同步，仅本地使用。
@DataClassName('MediaAssetRow')
class MediaAssets extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 来源：folder（桌面目录链接）| gallery（移动端相册引用）
  TextColumn get source => text().withDefault(const Constant('folder'))();

  /// type: image | video
  TextColumn get type => text().withDefault(const Constant('image'))();

  /// 本地绝对路径（folder）或相册 asset 标识（gallery）
  TextColumn get path => text()();

  /// 文件名（展示用）
  TextColumn get name => text()();

  IntColumn get sizeBytes => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  /// 所属素材目录（folder 来源；gallery 为 null）
  IntColumn get folderId =>
      integer().nullable().references(MediaFolders, #id)();

  /// 素材用途说明（用户批注：这张图是干嘛用的）
  TextColumn get purpose => text().nullable()();
}

/// 素材目录（链接不导入）：记录已链接的本地目录与用途说明。
@DataClassName('MediaFolderRow')
class MediaFolders extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 目录绝对路径（唯一）
  TextColumn get path => text().unique()();

  /// 目录名（展示用）
  TextColumn get name => text()();

  /// 目录用途说明（用户指定：这个目录里的素材是干嘛的）
  TextColumn get purpose => text().nullable()();

  DateTimeColumn get linkedAt => dateTime()();
}

/// 记忆集（记忆教练：用户自建的复习集合）：
/// 一个记忆集 = 一组收藏条目（卡片），可对集合整体学习/复习/回顾。
@DataClassName('MemorySetRow')
class MemorySets extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  /// 集合用途/说明
  TextColumn get purpose => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
}

/// 记忆集条目（收藏条目 → 记忆集 多对多）。
@DataClassName('MemorySetItemRow')
class MemorySetItems extends Table {
  IntColumn get memorySetId =>
      integer().references(MemorySets, #id, onDelete: KeyAction.cascade)();
  IntColumn get itemId =>
      integer().references(Items, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column<Object>> get primaryKey => {memorySetId, itemId};
}
