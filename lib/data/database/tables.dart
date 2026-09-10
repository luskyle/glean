import 'package:drift/drift.dart';

/// 收藏条目（Glean 核心：收藏管道的一等公民）
@DataClassName('ItemRow')
class Items extends Table {
  IntColumn get id => integer().autoIncrement()();

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

  /// 状态：active | inbox | archived（收藏整理用）
  TextColumn get status => text().withDefault(const Constant('inbox'))();
  DateTimeColumn get createdAt => dateTime()();
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
