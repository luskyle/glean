// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ItemsTable extends Items with TableInfo<$ItemsTable, ItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('manual'));
  static const VerificationMeta _mediaPathMeta =
      const VerificationMeta('mediaPath');
  @override
  late final GeneratedColumn<String> mediaPath = GeneratedColumn<String>(
      'media_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _originalUrlMeta =
      const VerificationMeta('originalUrl');
  @override
  late final GeneratedColumn<String> originalUrl = GeneratedColumn<String>(
      'original_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _mediaAssetIdMeta =
      const VerificationMeta('mediaAssetId');
  @override
  late final GeneratedColumn<int> mediaAssetId = GeneratedColumn<int>(
      'media_asset_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _sourceTitleMeta =
      const VerificationMeta('sourceTitle');
  @override
  late final GeneratedColumn<String> sourceTitle = GeneratedColumn<String>(
      'source_title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _htmlClipMeta =
      const VerificationMeta('htmlClip');
  @override
  late final GeneratedColumn<String> htmlClip = GeneratedColumn<String>(
      'html_clip', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _mediaTypeMeta =
      const VerificationMeta('mediaType');
  @override
  late final GeneratedColumn<String> mediaType = GeneratedColumn<String>(
      'media_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _coverUrlMeta =
      const VerificationMeta('coverUrl');
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
      'cover_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _langMeta = const VerificationMeta('lang');
  @override
  late final GeneratedColumn<String> lang = GeneratedColumn<String>(
      'lang', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('inbox'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        source,
        mediaPath,
        originalUrl,
        mediaAssetId,
        sourceTitle,
        htmlClip,
        mediaType,
        coverUrl,
        note,
        lang,
        status,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'items';
  @override
  VerificationContext validateIntegrity(Insertable<ItemRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    if (data.containsKey('media_path')) {
      context.handle(_mediaPathMeta,
          mediaPath.isAcceptableOrUnknown(data['media_path']!, _mediaPathMeta));
    }
    if (data.containsKey('original_url')) {
      context.handle(
          _originalUrlMeta,
          originalUrl.isAcceptableOrUnknown(
              data['original_url']!, _originalUrlMeta));
    }
    if (data.containsKey('media_asset_id')) {
      context.handle(
          _mediaAssetIdMeta,
          mediaAssetId.isAcceptableOrUnknown(
              data['media_asset_id']!, _mediaAssetIdMeta));
    }
    if (data.containsKey('source_title')) {
      context.handle(
          _sourceTitleMeta,
          sourceTitle.isAcceptableOrUnknown(
              data['source_title']!, _sourceTitleMeta));
    }
    if (data.containsKey('html_clip')) {
      context.handle(_htmlClipMeta,
          htmlClip.isAcceptableOrUnknown(data['html_clip']!, _htmlClipMeta));
    }
    if (data.containsKey('media_type')) {
      context.handle(_mediaTypeMeta,
          mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta));
    }
    if (data.containsKey('cover_url')) {
      context.handle(_coverUrlMeta,
          coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('lang')) {
      context.handle(
          _langMeta, lang.isAcceptableOrUnknown(data['lang']!, _langMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      mediaPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_path']),
      originalUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}original_url']),
      mediaAssetId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}media_asset_id']),
      sourceTitle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_title']),
      htmlClip: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}html_clip']),
      mediaType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_type']),
      coverUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_url']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      lang: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lang']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ItemsTable createAlias(String alias) {
    return $ItemsTable(attachedDatabase, alias);
  }
}

class ItemRow extends DataClass implements Insertable<ItemRow> {
  final int id;

  /// 来源：share | clipboard | photo | manual | anki_import
  final String source;
  final String? mediaPath;
  final String? originalUrl;

  /// 链接的本地素材（素材库引用，不随云同步；仅本地使用）
  final int? mediaAssetId;

  /// 网页摘录来源页标题（Phase 1：划词收藏自动带出处）
  final String? sourceTitle;

  /// 浏览器选区 HTML 快照（V1.1：划词收藏带入，App 只读渲染不执行脚本）
  final String? htmlClip;

  /// 媒体类型：image | video | audio | file（V1.1 浏览器端收藏直传）
  final String? mediaType;

  /// 封面/引用图 URL（og:image，网页 / 视频 / 音频收藏）
  final String? coverUrl;

  /// 用户备注（为什么收）
  final String? note;

  /// 语言标签（自动标注）
  final String? lang;

  /// 状态：active | inbox | archived（收藏整理用）
  final String status;
  final DateTime createdAt;
  const ItemRow(
      {required this.id,
      required this.source,
      this.mediaPath,
      this.originalUrl,
      this.mediaAssetId,
      this.sourceTitle,
      this.htmlClip,
      this.mediaType,
      this.coverUrl,
      this.note,
      this.lang,
      required this.status,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || mediaPath != null) {
      map['media_path'] = Variable<String>(mediaPath);
    }
    if (!nullToAbsent || originalUrl != null) {
      map['original_url'] = Variable<String>(originalUrl);
    }
    if (!nullToAbsent || mediaAssetId != null) {
      map['media_asset_id'] = Variable<int>(mediaAssetId);
    }
    if (!nullToAbsent || sourceTitle != null) {
      map['source_title'] = Variable<String>(sourceTitle);
    }
    if (!nullToAbsent || htmlClip != null) {
      map['html_clip'] = Variable<String>(htmlClip);
    }
    if (!nullToAbsent || mediaType != null) {
      map['media_type'] = Variable<String>(mediaType);
    }
    if (!nullToAbsent || coverUrl != null) {
      map['cover_url'] = Variable<String>(coverUrl);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || lang != null) {
      map['lang'] = Variable<String>(lang);
    }
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ItemsCompanion toCompanion(bool nullToAbsent) {
    return ItemsCompanion(
      id: Value(id),
      source: Value(source),
      mediaPath: mediaPath == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaPath),
      originalUrl: originalUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(originalUrl),
      mediaAssetId: mediaAssetId == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaAssetId),
      sourceTitle: sourceTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceTitle),
      htmlClip: htmlClip == null && nullToAbsent
          ? const Value.absent()
          : Value(htmlClip),
      mediaType: mediaType == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaType),
      coverUrl: coverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverUrl),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      lang: lang == null && nullToAbsent ? const Value.absent() : Value(lang),
      status: Value(status),
      createdAt: Value(createdAt),
    );
  }

  factory ItemRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemRow(
      id: serializer.fromJson<int>(json['id']),
      source: serializer.fromJson<String>(json['source']),
      mediaPath: serializer.fromJson<String?>(json['mediaPath']),
      originalUrl: serializer.fromJson<String?>(json['originalUrl']),
      mediaAssetId: serializer.fromJson<int?>(json['mediaAssetId']),
      sourceTitle: serializer.fromJson<String?>(json['sourceTitle']),
      htmlClip: serializer.fromJson<String?>(json['htmlClip']),
      mediaType: serializer.fromJson<String?>(json['mediaType']),
      coverUrl: serializer.fromJson<String?>(json['coverUrl']),
      note: serializer.fromJson<String?>(json['note']),
      lang: serializer.fromJson<String?>(json['lang']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'source': serializer.toJson<String>(source),
      'mediaPath': serializer.toJson<String?>(mediaPath),
      'originalUrl': serializer.toJson<String?>(originalUrl),
      'mediaAssetId': serializer.toJson<int?>(mediaAssetId),
      'sourceTitle': serializer.toJson<String?>(sourceTitle),
      'htmlClip': serializer.toJson<String?>(htmlClip),
      'mediaType': serializer.toJson<String?>(mediaType),
      'coverUrl': serializer.toJson<String?>(coverUrl),
      'note': serializer.toJson<String?>(note),
      'lang': serializer.toJson<String?>(lang),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ItemRow copyWith(
          {int? id,
          String? source,
          Value<String?> mediaPath = const Value.absent(),
          Value<String?> originalUrl = const Value.absent(),
          Value<int?> mediaAssetId = const Value.absent(),
          Value<String?> sourceTitle = const Value.absent(),
          Value<String?> htmlClip = const Value.absent(),
          Value<String?> mediaType = const Value.absent(),
          Value<String?> coverUrl = const Value.absent(),
          Value<String?> note = const Value.absent(),
          Value<String?> lang = const Value.absent(),
          String? status,
          DateTime? createdAt}) =>
      ItemRow(
        id: id ?? this.id,
        source: source ?? this.source,
        mediaPath: mediaPath.present ? mediaPath.value : this.mediaPath,
        originalUrl: originalUrl.present ? originalUrl.value : this.originalUrl,
        mediaAssetId:
            mediaAssetId.present ? mediaAssetId.value : this.mediaAssetId,
        sourceTitle: sourceTitle.present ? sourceTitle.value : this.sourceTitle,
        htmlClip: htmlClip.present ? htmlClip.value : this.htmlClip,
        mediaType: mediaType.present ? mediaType.value : this.mediaType,
        coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
        note: note.present ? note.value : this.note,
        lang: lang.present ? lang.value : this.lang,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
      );
  ItemRow copyWithCompanion(ItemsCompanion data) {
    return ItemRow(
      id: data.id.present ? data.id.value : this.id,
      source: data.source.present ? data.source.value : this.source,
      mediaPath: data.mediaPath.present ? data.mediaPath.value : this.mediaPath,
      originalUrl:
          data.originalUrl.present ? data.originalUrl.value : this.originalUrl,
      mediaAssetId: data.mediaAssetId.present
          ? data.mediaAssetId.value
          : this.mediaAssetId,
      sourceTitle:
          data.sourceTitle.present ? data.sourceTitle.value : this.sourceTitle,
      htmlClip: data.htmlClip.present ? data.htmlClip.value : this.htmlClip,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      note: data.note.present ? data.note.value : this.note,
      lang: data.lang.present ? data.lang.value : this.lang,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemRow(')
          ..write('id: $id, ')
          ..write('source: $source, ')
          ..write('mediaPath: $mediaPath, ')
          ..write('originalUrl: $originalUrl, ')
          ..write('mediaAssetId: $mediaAssetId, ')
          ..write('sourceTitle: $sourceTitle, ')
          ..write('htmlClip: $htmlClip, ')
          ..write('mediaType: $mediaType, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('note: $note, ')
          ..write('lang: $lang, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      source,
      mediaPath,
      originalUrl,
      mediaAssetId,
      sourceTitle,
      htmlClip,
      mediaType,
      coverUrl,
      note,
      lang,
      status,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemRow &&
          other.id == this.id &&
          other.source == this.source &&
          other.mediaPath == this.mediaPath &&
          other.originalUrl == this.originalUrl &&
          other.mediaAssetId == this.mediaAssetId &&
          other.sourceTitle == this.sourceTitle &&
          other.htmlClip == this.htmlClip &&
          other.mediaType == this.mediaType &&
          other.coverUrl == this.coverUrl &&
          other.note == this.note &&
          other.lang == this.lang &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class ItemsCompanion extends UpdateCompanion<ItemRow> {
  final Value<int> id;
  final Value<String> source;
  final Value<String?> mediaPath;
  final Value<String?> originalUrl;
  final Value<int?> mediaAssetId;
  final Value<String?> sourceTitle;
  final Value<String?> htmlClip;
  final Value<String?> mediaType;
  final Value<String?> coverUrl;
  final Value<String?> note;
  final Value<String?> lang;
  final Value<String> status;
  final Value<DateTime> createdAt;
  const ItemsCompanion({
    this.id = const Value.absent(),
    this.source = const Value.absent(),
    this.mediaPath = const Value.absent(),
    this.originalUrl = const Value.absent(),
    this.mediaAssetId = const Value.absent(),
    this.sourceTitle = const Value.absent(),
    this.htmlClip = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.note = const Value.absent(),
    this.lang = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ItemsCompanion.insert({
    this.id = const Value.absent(),
    this.source = const Value.absent(),
    this.mediaPath = const Value.absent(),
    this.originalUrl = const Value.absent(),
    this.mediaAssetId = const Value.absent(),
    this.sourceTitle = const Value.absent(),
    this.htmlClip = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.note = const Value.absent(),
    this.lang = const Value.absent(),
    this.status = const Value.absent(),
    required DateTime createdAt,
  }) : createdAt = Value(createdAt);
  static Insertable<ItemRow> custom({
    Expression<int>? id,
    Expression<String>? source,
    Expression<String>? mediaPath,
    Expression<String>? originalUrl,
    Expression<int>? mediaAssetId,
    Expression<String>? sourceTitle,
    Expression<String>? htmlClip,
    Expression<String>? mediaType,
    Expression<String>? coverUrl,
    Expression<String>? note,
    Expression<String>? lang,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (source != null) 'source': source,
      if (mediaPath != null) 'media_path': mediaPath,
      if (originalUrl != null) 'original_url': originalUrl,
      if (mediaAssetId != null) 'media_asset_id': mediaAssetId,
      if (sourceTitle != null) 'source_title': sourceTitle,
      if (htmlClip != null) 'html_clip': htmlClip,
      if (mediaType != null) 'media_type': mediaType,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (note != null) 'note': note,
      if (lang != null) 'lang': lang,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ItemsCompanion copyWith(
      {Value<int>? id,
      Value<String>? source,
      Value<String?>? mediaPath,
      Value<String?>? originalUrl,
      Value<int?>? mediaAssetId,
      Value<String?>? sourceTitle,
      Value<String?>? htmlClip,
      Value<String?>? mediaType,
      Value<String?>? coverUrl,
      Value<String?>? note,
      Value<String?>? lang,
      Value<String>? status,
      Value<DateTime>? createdAt}) {
    return ItemsCompanion(
      id: id ?? this.id,
      source: source ?? this.source,
      mediaPath: mediaPath ?? this.mediaPath,
      originalUrl: originalUrl ?? this.originalUrl,
      mediaAssetId: mediaAssetId ?? this.mediaAssetId,
      sourceTitle: sourceTitle ?? this.sourceTitle,
      htmlClip: htmlClip ?? this.htmlClip,
      mediaType: mediaType ?? this.mediaType,
      coverUrl: coverUrl ?? this.coverUrl,
      note: note ?? this.note,
      lang: lang ?? this.lang,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (mediaPath.present) {
      map['media_path'] = Variable<String>(mediaPath.value);
    }
    if (originalUrl.present) {
      map['original_url'] = Variable<String>(originalUrl.value);
    }
    if (mediaAssetId.present) {
      map['media_asset_id'] = Variable<int>(mediaAssetId.value);
    }
    if (sourceTitle.present) {
      map['source_title'] = Variable<String>(sourceTitle.value);
    }
    if (htmlClip.present) {
      map['html_clip'] = Variable<String>(htmlClip.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(mediaType.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (lang.present) {
      map['lang'] = Variable<String>(lang.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemsCompanion(')
          ..write('id: $id, ')
          ..write('source: $source, ')
          ..write('mediaPath: $mediaPath, ')
          ..write('originalUrl: $originalUrl, ')
          ..write('mediaAssetId: $mediaAssetId, ')
          ..write('sourceTitle: $sourceTitle, ')
          ..write('htmlClip: $htmlClip, ')
          ..write('mediaType: $mediaType, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('note: $note, ')
          ..write('lang: $lang, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CollectionsTable extends Collections
    with TableInfo<$CollectionsTable, CollectionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CollectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _parentIdMeta =
      const VerificationMeta('parentId');
  @override
  late final GeneratedColumn<int> parentId = GeneratedColumn<int>(
      'parent_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _ownerIdMeta =
      const VerificationMeta('ownerId');
  @override
  late final GeneratedColumn<int> ownerId = GeneratedColumn<int>(
      'owner_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _isSystemMeta =
      const VerificationMeta('isSystem');
  @override
  late final GeneratedColumn<bool> isSystem = GeneratedColumn<bool>(
      'is_system', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_system" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, parentId, ownerId, isSystem, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'collections';
  @override
  VerificationContext validateIntegrity(Insertable<CollectionRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(_parentIdMeta,
          parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta));
    }
    if (data.containsKey('owner_id')) {
      context.handle(_ownerIdMeta,
          ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta));
    }
    if (data.containsKey('is_system')) {
      context.handle(_isSystemMeta,
          isSystem.isAcceptableOrUnknown(data['is_system']!, _isSystemMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CollectionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CollectionRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      parentId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}parent_id']),
      ownerId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}owner_id']),
      isSystem: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_system'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $CollectionsTable createAlias(String alias) {
    return $CollectionsTable(attachedDatabase, alias);
  }
}

class CollectionRow extends DataClass implements Insertable<CollectionRow> {
  final int id;
  final String name;
  final int? parentId;
  final int? ownerId;
  final bool isSystem;
  final DateTime createdAt;
  const CollectionRow(
      {required this.id,
      required this.name,
      this.parentId,
      this.ownerId,
      required this.isSystem,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<int>(parentId);
    }
    if (!nullToAbsent || ownerId != null) {
      map['owner_id'] = Variable<int>(ownerId);
    }
    map['is_system'] = Variable<bool>(isSystem);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CollectionsCompanion toCompanion(bool nullToAbsent) {
    return CollectionsCompanion(
      id: Value(id),
      name: Value(name),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      ownerId: ownerId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerId),
      isSystem: Value(isSystem),
      createdAt: Value(createdAt),
    );
  }

  factory CollectionRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CollectionRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      parentId: serializer.fromJson<int?>(json['parentId']),
      ownerId: serializer.fromJson<int?>(json['ownerId']),
      isSystem: serializer.fromJson<bool>(json['isSystem']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'parentId': serializer.toJson<int?>(parentId),
      'ownerId': serializer.toJson<int?>(ownerId),
      'isSystem': serializer.toJson<bool>(isSystem),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CollectionRow copyWith(
          {int? id,
          String? name,
          Value<int?> parentId = const Value.absent(),
          Value<int?> ownerId = const Value.absent(),
          bool? isSystem,
          DateTime? createdAt}) =>
      CollectionRow(
        id: id ?? this.id,
        name: name ?? this.name,
        parentId: parentId.present ? parentId.value : this.parentId,
        ownerId: ownerId.present ? ownerId.value : this.ownerId,
        isSystem: isSystem ?? this.isSystem,
        createdAt: createdAt ?? this.createdAt,
      );
  CollectionRow copyWithCompanion(CollectionsCompanion data) {
    return CollectionRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      isSystem: data.isSystem.present ? data.isSystem.value : this.isSystem,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CollectionRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('ownerId: $ownerId, ')
          ..write('isSystem: $isSystem, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, parentId, ownerId, isSystem, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CollectionRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.parentId == this.parentId &&
          other.ownerId == this.ownerId &&
          other.isSystem == this.isSystem &&
          other.createdAt == this.createdAt);
}

class CollectionsCompanion extends UpdateCompanion<CollectionRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<int?> parentId;
  final Value<int?> ownerId;
  final Value<bool> isSystem;
  final Value<DateTime> createdAt;
  const CollectionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.parentId = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CollectionsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.parentId = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.isSystem = const Value.absent(),
    required DateTime createdAt,
  })  : name = Value(name),
        createdAt = Value(createdAt);
  static Insertable<CollectionRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? parentId,
    Expression<int>? ownerId,
    Expression<bool>? isSystem,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (parentId != null) 'parent_id': parentId,
      if (ownerId != null) 'owner_id': ownerId,
      if (isSystem != null) 'is_system': isSystem,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CollectionsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<int?>? parentId,
      Value<int?>? ownerId,
      Value<bool>? isSystem,
      Value<DateTime>? createdAt}) {
    return CollectionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      ownerId: ownerId ?? this.ownerId,
      isSystem: isSystem ?? this.isSystem,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<int>(parentId.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<int>(ownerId.value);
    }
    if (isSystem.present) {
      map['is_system'] = Variable<bool>(isSystem.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CollectionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('ownerId: $ownerId, ')
          ..write('isSystem: $isSystem, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ItemCollectionsTable extends ItemCollections
    with TableInfo<$ItemCollectionsTable, ItemCollectionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemCollectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
      'item_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _collectionIdMeta =
      const VerificationMeta('collectionId');
  @override
  late final GeneratedColumn<int> collectionId = GeneratedColumn<int>(
      'collection_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isPrimaryMeta =
      const VerificationMeta('isPrimary');
  @override
  late final GeneratedColumn<bool> isPrimary = GeneratedColumn<bool>(
      'is_primary', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_primary" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [itemId, collectionId, isPrimary];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'item_collections';
  @override
  VerificationContext validateIntegrity(Insertable<ItemCollectionRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('item_id')) {
      context.handle(_itemIdMeta,
          itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta));
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('collection_id')) {
      context.handle(
          _collectionIdMeta,
          collectionId.isAcceptableOrUnknown(
              data['collection_id']!, _collectionIdMeta));
    } else if (isInserting) {
      context.missing(_collectionIdMeta);
    }
    if (data.containsKey('is_primary')) {
      context.handle(_isPrimaryMeta,
          isPrimary.isAcceptableOrUnknown(data['is_primary']!, _isPrimaryMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {itemId, collectionId};
  @override
  ItemCollectionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemCollectionRow(
      itemId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}item_id'])!,
      collectionId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}collection_id'])!,
      isPrimary: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_primary'])!,
    );
  }

  @override
  $ItemCollectionsTable createAlias(String alias) {
    return $ItemCollectionsTable(attachedDatabase, alias);
  }
}

class ItemCollectionRow extends DataClass
    implements Insertable<ItemCollectionRow> {
  final int itemId;
  final int collectionId;
  final bool isPrimary;
  const ItemCollectionRow(
      {required this.itemId,
      required this.collectionId,
      required this.isPrimary});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['item_id'] = Variable<int>(itemId);
    map['collection_id'] = Variable<int>(collectionId);
    map['is_primary'] = Variable<bool>(isPrimary);
    return map;
  }

  ItemCollectionsCompanion toCompanion(bool nullToAbsent) {
    return ItemCollectionsCompanion(
      itemId: Value(itemId),
      collectionId: Value(collectionId),
      isPrimary: Value(isPrimary),
    );
  }

  factory ItemCollectionRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemCollectionRow(
      itemId: serializer.fromJson<int>(json['itemId']),
      collectionId: serializer.fromJson<int>(json['collectionId']),
      isPrimary: serializer.fromJson<bool>(json['isPrimary']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'itemId': serializer.toJson<int>(itemId),
      'collectionId': serializer.toJson<int>(collectionId),
      'isPrimary': serializer.toJson<bool>(isPrimary),
    };
  }

  ItemCollectionRow copyWith(
          {int? itemId, int? collectionId, bool? isPrimary}) =>
      ItemCollectionRow(
        itemId: itemId ?? this.itemId,
        collectionId: collectionId ?? this.collectionId,
        isPrimary: isPrimary ?? this.isPrimary,
      );
  ItemCollectionRow copyWithCompanion(ItemCollectionsCompanion data) {
    return ItemCollectionRow(
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      collectionId: data.collectionId.present
          ? data.collectionId.value
          : this.collectionId,
      isPrimary: data.isPrimary.present ? data.isPrimary.value : this.isPrimary,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemCollectionRow(')
          ..write('itemId: $itemId, ')
          ..write('collectionId: $collectionId, ')
          ..write('isPrimary: $isPrimary')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(itemId, collectionId, isPrimary);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemCollectionRow &&
          other.itemId == this.itemId &&
          other.collectionId == this.collectionId &&
          other.isPrimary == this.isPrimary);
}

class ItemCollectionsCompanion extends UpdateCompanion<ItemCollectionRow> {
  final Value<int> itemId;
  final Value<int> collectionId;
  final Value<bool> isPrimary;
  final Value<int> rowid;
  const ItemCollectionsCompanion({
    this.itemId = const Value.absent(),
    this.collectionId = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemCollectionsCompanion.insert({
    required int itemId,
    required int collectionId,
    this.isPrimary = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : itemId = Value(itemId),
        collectionId = Value(collectionId);
  static Insertable<ItemCollectionRow> custom({
    Expression<int>? itemId,
    Expression<int>? collectionId,
    Expression<bool>? isPrimary,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (itemId != null) 'item_id': itemId,
      if (collectionId != null) 'collection_id': collectionId,
      if (isPrimary != null) 'is_primary': isPrimary,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemCollectionsCompanion copyWith(
      {Value<int>? itemId,
      Value<int>? collectionId,
      Value<bool>? isPrimary,
      Value<int>? rowid}) {
    return ItemCollectionsCompanion(
      itemId: itemId ?? this.itemId,
      collectionId: collectionId ?? this.collectionId,
      isPrimary: isPrimary ?? this.isPrimary,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (collectionId.present) {
      map['collection_id'] = Variable<int>(collectionId.value);
    }
    if (isPrimary.present) {
      map['is_primary'] = Variable<bool>(isPrimary.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemCollectionsCompanion(')
          ..write('itemId: $itemId, ')
          ..write('collectionId: $collectionId, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ItemTagsTable extends ItemTags
    with TableInfo<$ItemTagsTable, ItemTagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
      'item_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  @override
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
      'tag', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [itemId, tag];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'item_tags';
  @override
  VerificationContext validateIntegrity(Insertable<ItemTagRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('item_id')) {
      context.handle(_itemIdMeta,
          itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta));
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('tag')) {
      context.handle(
          _tagMeta, tag.isAcceptableOrUnknown(data['tag']!, _tagMeta));
    } else if (isInserting) {
      context.missing(_tagMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {itemId, tag};
  @override
  ItemTagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemTagRow(
      itemId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}item_id'])!,
      tag: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tag'])!,
    );
  }

  @override
  $ItemTagsTable createAlias(String alias) {
    return $ItemTagsTable(attachedDatabase, alias);
  }
}

class ItemTagRow extends DataClass implements Insertable<ItemTagRow> {
  final int itemId;
  final String tag;
  const ItemTagRow({required this.itemId, required this.tag});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['item_id'] = Variable<int>(itemId);
    map['tag'] = Variable<String>(tag);
    return map;
  }

  ItemTagsCompanion toCompanion(bool nullToAbsent) {
    return ItemTagsCompanion(
      itemId: Value(itemId),
      tag: Value(tag),
    );
  }

  factory ItemTagRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemTagRow(
      itemId: serializer.fromJson<int>(json['itemId']),
      tag: serializer.fromJson<String>(json['tag']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'itemId': serializer.toJson<int>(itemId),
      'tag': serializer.toJson<String>(tag),
    };
  }

  ItemTagRow copyWith({int? itemId, String? tag}) => ItemTagRow(
        itemId: itemId ?? this.itemId,
        tag: tag ?? this.tag,
      );
  ItemTagRow copyWithCompanion(ItemTagsCompanion data) {
    return ItemTagRow(
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      tag: data.tag.present ? data.tag.value : this.tag,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemTagRow(')
          ..write('itemId: $itemId, ')
          ..write('tag: $tag')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(itemId, tag);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemTagRow &&
          other.itemId == this.itemId &&
          other.tag == this.tag);
}

class ItemTagsCompanion extends UpdateCompanion<ItemTagRow> {
  final Value<int> itemId;
  final Value<String> tag;
  final Value<int> rowid;
  const ItemTagsCompanion({
    this.itemId = const Value.absent(),
    this.tag = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemTagsCompanion.insert({
    required int itemId,
    required String tag,
    this.rowid = const Value.absent(),
  })  : itemId = Value(itemId),
        tag = Value(tag);
  static Insertable<ItemTagRow> custom({
    Expression<int>? itemId,
    Expression<String>? tag,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (itemId != null) 'item_id': itemId,
      if (tag != null) 'tag': tag,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemTagsCompanion copyWith(
      {Value<int>? itemId, Value<String>? tag, Value<int>? rowid}) {
    return ItemTagsCompanion(
      itemId: itemId ?? this.itemId,
      tag: tag ?? this.tag,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemTagsCompanion(')
          ..write('itemId: $itemId, ')
          ..write('tag: $tag, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncDeletionsTable extends SyncDeletions
    with TableInfo<$SyncDeletionsTable, SyncDeletionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncDeletionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityTableMeta =
      const VerificationMeta('entityTable');
  @override
  late final GeneratedColumn<String> entityTable = GeneratedColumn<String>(
      'entity_table', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<int> entityId = GeneratedColumn<int>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [entityTable, entityId, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_deletions';
  @override
  VerificationContext validateIntegrity(Insertable<SyncDeletionRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity_table')) {
      context.handle(
          _entityTableMeta,
          entityTable.isAcceptableOrUnknown(
              data['entity_table']!, _entityTableMeta));
    } else if (isInserting) {
      context.missing(_entityTableMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    } else if (isInserting) {
      context.missing(_deletedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entityTable, entityId};
  @override
  SyncDeletionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncDeletionRow(
      entityTable: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_table'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}entity_id'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at'])!,
    );
  }

  @override
  $SyncDeletionsTable createAlias(String alias) {
    return $SyncDeletionsTable(attachedDatabase, alias);
  }
}

class SyncDeletionRow extends DataClass implements Insertable<SyncDeletionRow> {
  final String entityTable;
  final int entityId;
  final DateTime deletedAt;
  const SyncDeletionRow(
      {required this.entityTable,
      required this.entityId,
      required this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity_table'] = Variable<String>(entityTable);
    map['entity_id'] = Variable<int>(entityId);
    map['deleted_at'] = Variable<DateTime>(deletedAt);
    return map;
  }

  SyncDeletionsCompanion toCompanion(bool nullToAbsent) {
    return SyncDeletionsCompanion(
      entityTable: Value(entityTable),
      entityId: Value(entityId),
      deletedAt: Value(deletedAt),
    );
  }

  factory SyncDeletionRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncDeletionRow(
      entityTable: serializer.fromJson<String>(json['entityTable']),
      entityId: serializer.fromJson<int>(json['entityId']),
      deletedAt: serializer.fromJson<DateTime>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entityTable': serializer.toJson<String>(entityTable),
      'entityId': serializer.toJson<int>(entityId),
      'deletedAt': serializer.toJson<DateTime>(deletedAt),
    };
  }

  SyncDeletionRow copyWith(
          {String? entityTable, int? entityId, DateTime? deletedAt}) =>
      SyncDeletionRow(
        entityTable: entityTable ?? this.entityTable,
        entityId: entityId ?? this.entityId,
        deletedAt: deletedAt ?? this.deletedAt,
      );
  SyncDeletionRow copyWithCompanion(SyncDeletionsCompanion data) {
    return SyncDeletionRow(
      entityTable:
          data.entityTable.present ? data.entityTable.value : this.entityTable,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncDeletionRow(')
          ..write('entityTable: $entityTable, ')
          ..write('entityId: $entityId, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entityTable, entityId, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncDeletionRow &&
          other.entityTable == this.entityTable &&
          other.entityId == this.entityId &&
          other.deletedAt == this.deletedAt);
}

class SyncDeletionsCompanion extends UpdateCompanion<SyncDeletionRow> {
  final Value<String> entityTable;
  final Value<int> entityId;
  final Value<DateTime> deletedAt;
  final Value<int> rowid;
  const SyncDeletionsCompanion({
    this.entityTable = const Value.absent(),
    this.entityId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncDeletionsCompanion.insert({
    required String entityTable,
    required int entityId,
    required DateTime deletedAt,
    this.rowid = const Value.absent(),
  })  : entityTable = Value(entityTable),
        entityId = Value(entityId),
        deletedAt = Value(deletedAt);
  static Insertable<SyncDeletionRow> custom({
    Expression<String>? entityTable,
    Expression<int>? entityId,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entityTable != null) 'entity_table': entityTable,
      if (entityId != null) 'entity_id': entityId,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncDeletionsCompanion copyWith(
      {Value<String>? entityTable,
      Value<int>? entityId,
      Value<DateTime>? deletedAt,
      Value<int>? rowid}) {
    return SyncDeletionsCompanion(
      entityTable: entityTable ?? this.entityTable,
      entityId: entityId ?? this.entityId,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entityTable.present) {
      map['entity_table'] = Variable<String>(entityTable.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<int>(entityId.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncDeletionsCompanion(')
          ..write('entityTable: $entityTable, ')
          ..write('entityId: $entityId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MediaAssetsTable extends MediaAssets
    with TableInfo<$MediaAssetsTable, MediaAssetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaAssetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('folder'));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('image'));
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
      'path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sizeBytesMeta =
      const VerificationMeta('sizeBytes');
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
      'size_bytes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _folderIdMeta =
      const VerificationMeta('folderId');
  @override
  late final GeneratedColumn<int> folderId = GeneratedColumn<int>(
      'folder_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _purposeMeta =
      const VerificationMeta('purpose');
  @override
  late final GeneratedColumn<String> purpose = GeneratedColumn<String>(
      'purpose', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, source, type, path, name, sizeBytes, createdAt, folderId, purpose];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_assets';
  @override
  VerificationContext validateIntegrity(Insertable<MediaAssetRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    }
    if (data.containsKey('path')) {
      context.handle(
          _pathMeta, path.isAcceptableOrUnknown(data['path']!, _pathMeta));
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(_sizeBytesMeta,
          sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('folder_id')) {
      context.handle(_folderIdMeta,
          folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta));
    }
    if (data.containsKey('purpose')) {
      context.handle(_purposeMeta,
          purpose.isAcceptableOrUnknown(data['purpose']!, _purposeMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MediaAssetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaAssetRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      path: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}path'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      sizeBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}size_bytes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      folderId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}folder_id']),
      purpose: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}purpose']),
    );
  }

  @override
  $MediaAssetsTable createAlias(String alias) {
    return $MediaAssetsTable(attachedDatabase, alias);
  }
}

class MediaAssetRow extends DataClass implements Insertable<MediaAssetRow> {
  final int id;

  /// 来源：folder（桌面目录链接）| gallery（移动端相册引用）
  final String source;

  /// type: image | video
  final String type;

  /// 本地绝对路径（folder）或相册 asset 标识（gallery）
  final String path;

  /// 文件名（展示用）
  final String name;
  final int? sizeBytes;
  final DateTime createdAt;

  /// 所属素材目录（folder 来源；gallery 为 null）
  final int? folderId;

  /// 素材用途说明（用户批注：这张图是干嘛用的）
  final String? purpose;
  const MediaAssetRow(
      {required this.id,
      required this.source,
      required this.type,
      required this.path,
      required this.name,
      this.sizeBytes,
      required this.createdAt,
      this.folderId,
      this.purpose});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['source'] = Variable<String>(source);
    map['type'] = Variable<String>(type);
    map['path'] = Variable<String>(path);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || sizeBytes != null) {
      map['size_bytes'] = Variable<int>(sizeBytes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || folderId != null) {
      map['folder_id'] = Variable<int>(folderId);
    }
    if (!nullToAbsent || purpose != null) {
      map['purpose'] = Variable<String>(purpose);
    }
    return map;
  }

  MediaAssetsCompanion toCompanion(bool nullToAbsent) {
    return MediaAssetsCompanion(
      id: Value(id),
      source: Value(source),
      type: Value(type),
      path: Value(path),
      name: Value(name),
      sizeBytes: sizeBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(sizeBytes),
      createdAt: Value(createdAt),
      folderId: folderId == null && nullToAbsent
          ? const Value.absent()
          : Value(folderId),
      purpose: purpose == null && nullToAbsent
          ? const Value.absent()
          : Value(purpose),
    );
  }

  factory MediaAssetRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaAssetRow(
      id: serializer.fromJson<int>(json['id']),
      source: serializer.fromJson<String>(json['source']),
      type: serializer.fromJson<String>(json['type']),
      path: serializer.fromJson<String>(json['path']),
      name: serializer.fromJson<String>(json['name']),
      sizeBytes: serializer.fromJson<int?>(json['sizeBytes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      folderId: serializer.fromJson<int?>(json['folderId']),
      purpose: serializer.fromJson<String?>(json['purpose']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'source': serializer.toJson<String>(source),
      'type': serializer.toJson<String>(type),
      'path': serializer.toJson<String>(path),
      'name': serializer.toJson<String>(name),
      'sizeBytes': serializer.toJson<int?>(sizeBytes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'folderId': serializer.toJson<int?>(folderId),
      'purpose': serializer.toJson<String?>(purpose),
    };
  }

  MediaAssetRow copyWith(
          {int? id,
          String? source,
          String? type,
          String? path,
          String? name,
          Value<int?> sizeBytes = const Value.absent(),
          DateTime? createdAt,
          Value<int?> folderId = const Value.absent(),
          Value<String?> purpose = const Value.absent()}) =>
      MediaAssetRow(
        id: id ?? this.id,
        source: source ?? this.source,
        type: type ?? this.type,
        path: path ?? this.path,
        name: name ?? this.name,
        sizeBytes: sizeBytes.present ? sizeBytes.value : this.sizeBytes,
        createdAt: createdAt ?? this.createdAt,
        folderId: folderId.present ? folderId.value : this.folderId,
        purpose: purpose.present ? purpose.value : this.purpose,
      );
  MediaAssetRow copyWithCompanion(MediaAssetsCompanion data) {
    return MediaAssetRow(
      id: data.id.present ? data.id.value : this.id,
      source: data.source.present ? data.source.value : this.source,
      type: data.type.present ? data.type.value : this.type,
      path: data.path.present ? data.path.value : this.path,
      name: data.name.present ? data.name.value : this.name,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      purpose: data.purpose.present ? data.purpose.value : this.purpose,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaAssetRow(')
          ..write('id: $id, ')
          ..write('source: $source, ')
          ..write('type: $type, ')
          ..write('path: $path, ')
          ..write('name: $name, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('createdAt: $createdAt, ')
          ..write('folderId: $folderId, ')
          ..write('purpose: $purpose')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, source, type, path, name, sizeBytes, createdAt, folderId, purpose);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaAssetRow &&
          other.id == this.id &&
          other.source == this.source &&
          other.type == this.type &&
          other.path == this.path &&
          other.name == this.name &&
          other.sizeBytes == this.sizeBytes &&
          other.createdAt == this.createdAt &&
          other.folderId == this.folderId &&
          other.purpose == this.purpose);
}

class MediaAssetsCompanion extends UpdateCompanion<MediaAssetRow> {
  final Value<int> id;
  final Value<String> source;
  final Value<String> type;
  final Value<String> path;
  final Value<String> name;
  final Value<int?> sizeBytes;
  final Value<DateTime> createdAt;
  final Value<int?> folderId;
  final Value<String?> purpose;
  const MediaAssetsCompanion({
    this.id = const Value.absent(),
    this.source = const Value.absent(),
    this.type = const Value.absent(),
    this.path = const Value.absent(),
    this.name = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.folderId = const Value.absent(),
    this.purpose = const Value.absent(),
  });
  MediaAssetsCompanion.insert({
    this.id = const Value.absent(),
    this.source = const Value.absent(),
    this.type = const Value.absent(),
    required String path,
    required String name,
    this.sizeBytes = const Value.absent(),
    required DateTime createdAt,
    this.folderId = const Value.absent(),
    this.purpose = const Value.absent(),
  })  : path = Value(path),
        name = Value(name),
        createdAt = Value(createdAt);
  static Insertable<MediaAssetRow> custom({
    Expression<int>? id,
    Expression<String>? source,
    Expression<String>? type,
    Expression<String>? path,
    Expression<String>? name,
    Expression<int>? sizeBytes,
    Expression<DateTime>? createdAt,
    Expression<int>? folderId,
    Expression<String>? purpose,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (source != null) 'source': source,
      if (type != null) 'type': type,
      if (path != null) 'path': path,
      if (name != null) 'name': name,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (createdAt != null) 'created_at': createdAt,
      if (folderId != null) 'folder_id': folderId,
      if (purpose != null) 'purpose': purpose,
    });
  }

  MediaAssetsCompanion copyWith(
      {Value<int>? id,
      Value<String>? source,
      Value<String>? type,
      Value<String>? path,
      Value<String>? name,
      Value<int?>? sizeBytes,
      Value<DateTime>? createdAt,
      Value<int?>? folderId,
      Value<String?>? purpose}) {
    return MediaAssetsCompanion(
      id: id ?? this.id,
      source: source ?? this.source,
      type: type ?? this.type,
      path: path ?? this.path,
      name: name ?? this.name,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      createdAt: createdAt ?? this.createdAt,
      folderId: folderId ?? this.folderId,
      purpose: purpose ?? this.purpose,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<int>(folderId.value);
    }
    if (purpose.present) {
      map['purpose'] = Variable<String>(purpose.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaAssetsCompanion(')
          ..write('id: $id, ')
          ..write('source: $source, ')
          ..write('type: $type, ')
          ..write('path: $path, ')
          ..write('name: $name, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('createdAt: $createdAt, ')
          ..write('folderId: $folderId, ')
          ..write('purpose: $purpose')
          ..write(')'))
        .toString();
  }
}

class $MediaFoldersTable extends MediaFolders
    with TableInfo<$MediaFoldersTable, MediaFolderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaFoldersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
      'path', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _purposeMeta =
      const VerificationMeta('purpose');
  @override
  late final GeneratedColumn<String> purpose = GeneratedColumn<String>(
      'purpose', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _linkedAtMeta =
      const VerificationMeta('linkedAt');
  @override
  late final GeneratedColumn<DateTime> linkedAt = GeneratedColumn<DateTime>(
      'linked_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, path, name, purpose, linkedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_folders';
  @override
  VerificationContext validateIntegrity(Insertable<MediaFolderRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('path')) {
      context.handle(
          _pathMeta, path.isAcceptableOrUnknown(data['path']!, _pathMeta));
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('purpose')) {
      context.handle(_purposeMeta,
          purpose.isAcceptableOrUnknown(data['purpose']!, _purposeMeta));
    }
    if (data.containsKey('linked_at')) {
      context.handle(_linkedAtMeta,
          linkedAt.isAcceptableOrUnknown(data['linked_at']!, _linkedAtMeta));
    } else if (isInserting) {
      context.missing(_linkedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MediaFolderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaFolderRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      path: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}path'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      purpose: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}purpose']),
      linkedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}linked_at'])!,
    );
  }

  @override
  $MediaFoldersTable createAlias(String alias) {
    return $MediaFoldersTable(attachedDatabase, alias);
  }
}

class MediaFolderRow extends DataClass implements Insertable<MediaFolderRow> {
  final int id;

  /// 目录绝对路径（唯一）
  final String path;

  /// 目录名（展示用）
  final String name;

  /// 目录用途说明（用户指定：这个目录里的素材是干嘛的）
  final String? purpose;
  final DateTime linkedAt;
  const MediaFolderRow(
      {required this.id,
      required this.path,
      required this.name,
      this.purpose,
      required this.linkedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['path'] = Variable<String>(path);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || purpose != null) {
      map['purpose'] = Variable<String>(purpose);
    }
    map['linked_at'] = Variable<DateTime>(linkedAt);
    return map;
  }

  MediaFoldersCompanion toCompanion(bool nullToAbsent) {
    return MediaFoldersCompanion(
      id: Value(id),
      path: Value(path),
      name: Value(name),
      purpose: purpose == null && nullToAbsent
          ? const Value.absent()
          : Value(purpose),
      linkedAt: Value(linkedAt),
    );
  }

  factory MediaFolderRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaFolderRow(
      id: serializer.fromJson<int>(json['id']),
      path: serializer.fromJson<String>(json['path']),
      name: serializer.fromJson<String>(json['name']),
      purpose: serializer.fromJson<String?>(json['purpose']),
      linkedAt: serializer.fromJson<DateTime>(json['linkedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'path': serializer.toJson<String>(path),
      'name': serializer.toJson<String>(name),
      'purpose': serializer.toJson<String?>(purpose),
      'linkedAt': serializer.toJson<DateTime>(linkedAt),
    };
  }

  MediaFolderRow copyWith(
          {int? id,
          String? path,
          String? name,
          Value<String?> purpose = const Value.absent(),
          DateTime? linkedAt}) =>
      MediaFolderRow(
        id: id ?? this.id,
        path: path ?? this.path,
        name: name ?? this.name,
        purpose: purpose.present ? purpose.value : this.purpose,
        linkedAt: linkedAt ?? this.linkedAt,
      );
  MediaFolderRow copyWithCompanion(MediaFoldersCompanion data) {
    return MediaFolderRow(
      id: data.id.present ? data.id.value : this.id,
      path: data.path.present ? data.path.value : this.path,
      name: data.name.present ? data.name.value : this.name,
      purpose: data.purpose.present ? data.purpose.value : this.purpose,
      linkedAt: data.linkedAt.present ? data.linkedAt.value : this.linkedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaFolderRow(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('name: $name, ')
          ..write('purpose: $purpose, ')
          ..write('linkedAt: $linkedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, path, name, purpose, linkedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaFolderRow &&
          other.id == this.id &&
          other.path == this.path &&
          other.name == this.name &&
          other.purpose == this.purpose &&
          other.linkedAt == this.linkedAt);
}

class MediaFoldersCompanion extends UpdateCompanion<MediaFolderRow> {
  final Value<int> id;
  final Value<String> path;
  final Value<String> name;
  final Value<String?> purpose;
  final Value<DateTime> linkedAt;
  const MediaFoldersCompanion({
    this.id = const Value.absent(),
    this.path = const Value.absent(),
    this.name = const Value.absent(),
    this.purpose = const Value.absent(),
    this.linkedAt = const Value.absent(),
  });
  MediaFoldersCompanion.insert({
    this.id = const Value.absent(),
    required String path,
    required String name,
    this.purpose = const Value.absent(),
    required DateTime linkedAt,
  })  : path = Value(path),
        name = Value(name),
        linkedAt = Value(linkedAt);
  static Insertable<MediaFolderRow> custom({
    Expression<int>? id,
    Expression<String>? path,
    Expression<String>? name,
    Expression<String>? purpose,
    Expression<DateTime>? linkedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (path != null) 'path': path,
      if (name != null) 'name': name,
      if (purpose != null) 'purpose': purpose,
      if (linkedAt != null) 'linked_at': linkedAt,
    });
  }

  MediaFoldersCompanion copyWith(
      {Value<int>? id,
      Value<String>? path,
      Value<String>? name,
      Value<String?>? purpose,
      Value<DateTime>? linkedAt}) {
    return MediaFoldersCompanion(
      id: id ?? this.id,
      path: path ?? this.path,
      name: name ?? this.name,
      purpose: purpose ?? this.purpose,
      linkedAt: linkedAt ?? this.linkedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (purpose.present) {
      map['purpose'] = Variable<String>(purpose.value);
    }
    if (linkedAt.present) {
      map['linked_at'] = Variable<DateTime>(linkedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaFoldersCompanion(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('name: $name, ')
          ..write('purpose: $purpose, ')
          ..write('linkedAt: $linkedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ItemsTable items = $ItemsTable(this);
  late final $CollectionsTable collections = $CollectionsTable(this);
  late final $ItemCollectionsTable itemCollections =
      $ItemCollectionsTable(this);
  late final $ItemTagsTable itemTags = $ItemTagsTable(this);
  late final $SyncDeletionsTable syncDeletions = $SyncDeletionsTable(this);
  late final $MediaAssetsTable mediaAssets = $MediaAssetsTable(this);
  late final $MediaFoldersTable mediaFolders = $MediaFoldersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        items,
        collections,
        itemCollections,
        itemTags,
        syncDeletions,
        mediaAssets,
        mediaFolders
      ];
}

typedef $$ItemsTableCreateCompanionBuilder = ItemsCompanion Function({
  Value<int> id,
  Value<String> source,
  Value<String?> mediaPath,
  Value<String?> originalUrl,
  Value<int?> mediaAssetId,
  Value<String?> sourceTitle,
  Value<String?> htmlClip,
  Value<String?> mediaType,
  Value<String?> coverUrl,
  Value<String?> note,
  Value<String?> lang,
  Value<String> status,
  required DateTime createdAt,
});
typedef $$ItemsTableUpdateCompanionBuilder = ItemsCompanion Function({
  Value<int> id,
  Value<String> source,
  Value<String?> mediaPath,
  Value<String?> originalUrl,
  Value<int?> mediaAssetId,
  Value<String?> sourceTitle,
  Value<String?> htmlClip,
  Value<String?> mediaType,
  Value<String?> coverUrl,
  Value<String?> note,
  Value<String?> lang,
  Value<String> status,
  Value<DateTime> createdAt,
});

class $$ItemsTableFilterComposer extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mediaPath => $composableBuilder(
      column: $table.mediaPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get originalUrl => $composableBuilder(
      column: $table.originalUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get mediaAssetId => $composableBuilder(
      column: $table.mediaAssetId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceTitle => $composableBuilder(
      column: $table.sourceTitle, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get htmlClip => $composableBuilder(
      column: $table.htmlClip, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mediaType => $composableBuilder(
      column: $table.mediaType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverUrl => $composableBuilder(
      column: $table.coverUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lang => $composableBuilder(
      column: $table.lang, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$ItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mediaPath => $composableBuilder(
      column: $table.mediaPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get originalUrl => $composableBuilder(
      column: $table.originalUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get mediaAssetId => $composableBuilder(
      column: $table.mediaAssetId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceTitle => $composableBuilder(
      column: $table.sourceTitle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get htmlClip => $composableBuilder(
      column: $table.htmlClip, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mediaType => $composableBuilder(
      column: $table.mediaType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverUrl => $composableBuilder(
      column: $table.coverUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lang => $composableBuilder(
      column: $table.lang, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$ItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get mediaPath =>
      $composableBuilder(column: $table.mediaPath, builder: (column) => column);

  GeneratedColumn<String> get originalUrl => $composableBuilder(
      column: $table.originalUrl, builder: (column) => column);

  GeneratedColumn<int> get mediaAssetId => $composableBuilder(
      column: $table.mediaAssetId, builder: (column) => column);

  GeneratedColumn<String> get sourceTitle => $composableBuilder(
      column: $table.sourceTitle, builder: (column) => column);

  GeneratedColumn<String> get htmlClip =>
      $composableBuilder(column: $table.htmlClip, builder: (column) => column);

  GeneratedColumn<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get lang =>
      $composableBuilder(column: $table.lang, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ItemsTable,
    ItemRow,
    $$ItemsTableFilterComposer,
    $$ItemsTableOrderingComposer,
    $$ItemsTableAnnotationComposer,
    $$ItemsTableCreateCompanionBuilder,
    $$ItemsTableUpdateCompanionBuilder,
    (ItemRow, BaseReferences<_$AppDatabase, $ItemsTable, ItemRow>),
    ItemRow,
    PrefetchHooks Function()> {
  $$ItemsTableTableManager(_$AppDatabase db, $ItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String?> mediaPath = const Value.absent(),
            Value<String?> originalUrl = const Value.absent(),
            Value<int?> mediaAssetId = const Value.absent(),
            Value<String?> sourceTitle = const Value.absent(),
            Value<String?> htmlClip = const Value.absent(),
            Value<String?> mediaType = const Value.absent(),
            Value<String?> coverUrl = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String?> lang = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              ItemsCompanion(
            id: id,
            source: source,
            mediaPath: mediaPath,
            originalUrl: originalUrl,
            mediaAssetId: mediaAssetId,
            sourceTitle: sourceTitle,
            htmlClip: htmlClip,
            mediaType: mediaType,
            coverUrl: coverUrl,
            note: note,
            lang: lang,
            status: status,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String?> mediaPath = const Value.absent(),
            Value<String?> originalUrl = const Value.absent(),
            Value<int?> mediaAssetId = const Value.absent(),
            Value<String?> sourceTitle = const Value.absent(),
            Value<String?> htmlClip = const Value.absent(),
            Value<String?> mediaType = const Value.absent(),
            Value<String?> coverUrl = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String?> lang = const Value.absent(),
            Value<String> status = const Value.absent(),
            required DateTime createdAt,
          }) =>
              ItemsCompanion.insert(
            id: id,
            source: source,
            mediaPath: mediaPath,
            originalUrl: originalUrl,
            mediaAssetId: mediaAssetId,
            sourceTitle: sourceTitle,
            htmlClip: htmlClip,
            mediaType: mediaType,
            coverUrl: coverUrl,
            note: note,
            lang: lang,
            status: status,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ItemsTable,
    ItemRow,
    $$ItemsTableFilterComposer,
    $$ItemsTableOrderingComposer,
    $$ItemsTableAnnotationComposer,
    $$ItemsTableCreateCompanionBuilder,
    $$ItemsTableUpdateCompanionBuilder,
    (ItemRow, BaseReferences<_$AppDatabase, $ItemsTable, ItemRow>),
    ItemRow,
    PrefetchHooks Function()>;
typedef $$CollectionsTableCreateCompanionBuilder = CollectionsCompanion
    Function({
  Value<int> id,
  required String name,
  Value<int?> parentId,
  Value<int?> ownerId,
  Value<bool> isSystem,
  required DateTime createdAt,
});
typedef $$CollectionsTableUpdateCompanionBuilder = CollectionsCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<int?> parentId,
  Value<int?> ownerId,
  Value<bool> isSystem,
  Value<DateTime> createdAt,
});

class $$CollectionsTableFilterComposer
    extends Composer<_$AppDatabase, $CollectionsTable> {
  $$CollectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get parentId => $composableBuilder(
      column: $table.parentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSystem => $composableBuilder(
      column: $table.isSystem, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$CollectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CollectionsTable> {
  $$CollectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get parentId => $composableBuilder(
      column: $table.parentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSystem => $composableBuilder(
      column: $table.isSystem, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$CollectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CollectionsTable> {
  $$CollectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<int> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<bool> get isSystem =>
      $composableBuilder(column: $table.isSystem, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CollectionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CollectionsTable,
    CollectionRow,
    $$CollectionsTableFilterComposer,
    $$CollectionsTableOrderingComposer,
    $$CollectionsTableAnnotationComposer,
    $$CollectionsTableCreateCompanionBuilder,
    $$CollectionsTableUpdateCompanionBuilder,
    (
      CollectionRow,
      BaseReferences<_$AppDatabase, $CollectionsTable, CollectionRow>
    ),
    CollectionRow,
    PrefetchHooks Function()> {
  $$CollectionsTableTableManager(_$AppDatabase db, $CollectionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CollectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CollectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CollectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int?> parentId = const Value.absent(),
            Value<int?> ownerId = const Value.absent(),
            Value<bool> isSystem = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              CollectionsCompanion(
            id: id,
            name: name,
            parentId: parentId,
            ownerId: ownerId,
            isSystem: isSystem,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<int?> parentId = const Value.absent(),
            Value<int?> ownerId = const Value.absent(),
            Value<bool> isSystem = const Value.absent(),
            required DateTime createdAt,
          }) =>
              CollectionsCompanion.insert(
            id: id,
            name: name,
            parentId: parentId,
            ownerId: ownerId,
            isSystem: isSystem,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CollectionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CollectionsTable,
    CollectionRow,
    $$CollectionsTableFilterComposer,
    $$CollectionsTableOrderingComposer,
    $$CollectionsTableAnnotationComposer,
    $$CollectionsTableCreateCompanionBuilder,
    $$CollectionsTableUpdateCompanionBuilder,
    (
      CollectionRow,
      BaseReferences<_$AppDatabase, $CollectionsTable, CollectionRow>
    ),
    CollectionRow,
    PrefetchHooks Function()>;
typedef $$ItemCollectionsTableCreateCompanionBuilder = ItemCollectionsCompanion
    Function({
  required int itemId,
  required int collectionId,
  Value<bool> isPrimary,
  Value<int> rowid,
});
typedef $$ItemCollectionsTableUpdateCompanionBuilder = ItemCollectionsCompanion
    Function({
  Value<int> itemId,
  Value<int> collectionId,
  Value<bool> isPrimary,
  Value<int> rowid,
});

class $$ItemCollectionsTableFilterComposer
    extends Composer<_$AppDatabase, $ItemCollectionsTable> {
  $$ItemCollectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get collectionId => $composableBuilder(
      column: $table.collectionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPrimary => $composableBuilder(
      column: $table.isPrimary, builder: (column) => ColumnFilters(column));
}

class $$ItemCollectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemCollectionsTable> {
  $$ItemCollectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get collectionId => $composableBuilder(
      column: $table.collectionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPrimary => $composableBuilder(
      column: $table.isPrimary, builder: (column) => ColumnOrderings(column));
}

class $$ItemCollectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemCollectionsTable> {
  $$ItemCollectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<int> get collectionId => $composableBuilder(
      column: $table.collectionId, builder: (column) => column);

  GeneratedColumn<bool> get isPrimary =>
      $composableBuilder(column: $table.isPrimary, builder: (column) => column);
}

class $$ItemCollectionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ItemCollectionsTable,
    ItemCollectionRow,
    $$ItemCollectionsTableFilterComposer,
    $$ItemCollectionsTableOrderingComposer,
    $$ItemCollectionsTableAnnotationComposer,
    $$ItemCollectionsTableCreateCompanionBuilder,
    $$ItemCollectionsTableUpdateCompanionBuilder,
    (
      ItemCollectionRow,
      BaseReferences<_$AppDatabase, $ItemCollectionsTable, ItemCollectionRow>
    ),
    ItemCollectionRow,
    PrefetchHooks Function()> {
  $$ItemCollectionsTableTableManager(
      _$AppDatabase db, $ItemCollectionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemCollectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemCollectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemCollectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> itemId = const Value.absent(),
            Value<int> collectionId = const Value.absent(),
            Value<bool> isPrimary = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ItemCollectionsCompanion(
            itemId: itemId,
            collectionId: collectionId,
            isPrimary: isPrimary,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int itemId,
            required int collectionId,
            Value<bool> isPrimary = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ItemCollectionsCompanion.insert(
            itemId: itemId,
            collectionId: collectionId,
            isPrimary: isPrimary,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ItemCollectionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ItemCollectionsTable,
    ItemCollectionRow,
    $$ItemCollectionsTableFilterComposer,
    $$ItemCollectionsTableOrderingComposer,
    $$ItemCollectionsTableAnnotationComposer,
    $$ItemCollectionsTableCreateCompanionBuilder,
    $$ItemCollectionsTableUpdateCompanionBuilder,
    (
      ItemCollectionRow,
      BaseReferences<_$AppDatabase, $ItemCollectionsTable, ItemCollectionRow>
    ),
    ItemCollectionRow,
    PrefetchHooks Function()>;
typedef $$ItemTagsTableCreateCompanionBuilder = ItemTagsCompanion Function({
  required int itemId,
  required String tag,
  Value<int> rowid,
});
typedef $$ItemTagsTableUpdateCompanionBuilder = ItemTagsCompanion Function({
  Value<int> itemId,
  Value<String> tag,
  Value<int> rowid,
});

class $$ItemTagsTableFilterComposer
    extends Composer<_$AppDatabase, $ItemTagsTable> {
  $$ItemTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tag => $composableBuilder(
      column: $table.tag, builder: (column) => ColumnFilters(column));
}

class $$ItemTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemTagsTable> {
  $$ItemTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tag => $composableBuilder(
      column: $table.tag, builder: (column) => ColumnOrderings(column));
}

class $$ItemTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemTagsTable> {
  $$ItemTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => column);
}

class $$ItemTagsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ItemTagsTable,
    ItemTagRow,
    $$ItemTagsTableFilterComposer,
    $$ItemTagsTableOrderingComposer,
    $$ItemTagsTableAnnotationComposer,
    $$ItemTagsTableCreateCompanionBuilder,
    $$ItemTagsTableUpdateCompanionBuilder,
    (ItemTagRow, BaseReferences<_$AppDatabase, $ItemTagsTable, ItemTagRow>),
    ItemTagRow,
    PrefetchHooks Function()> {
  $$ItemTagsTableTableManager(_$AppDatabase db, $ItemTagsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> itemId = const Value.absent(),
            Value<String> tag = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ItemTagsCompanion(
            itemId: itemId,
            tag: tag,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int itemId,
            required String tag,
            Value<int> rowid = const Value.absent(),
          }) =>
              ItemTagsCompanion.insert(
            itemId: itemId,
            tag: tag,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ItemTagsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ItemTagsTable,
    ItemTagRow,
    $$ItemTagsTableFilterComposer,
    $$ItemTagsTableOrderingComposer,
    $$ItemTagsTableAnnotationComposer,
    $$ItemTagsTableCreateCompanionBuilder,
    $$ItemTagsTableUpdateCompanionBuilder,
    (ItemTagRow, BaseReferences<_$AppDatabase, $ItemTagsTable, ItemTagRow>),
    ItemTagRow,
    PrefetchHooks Function()>;
typedef $$SyncDeletionsTableCreateCompanionBuilder = SyncDeletionsCompanion
    Function({
  required String entityTable,
  required int entityId,
  required DateTime deletedAt,
  Value<int> rowid,
});
typedef $$SyncDeletionsTableUpdateCompanionBuilder = SyncDeletionsCompanion
    Function({
  Value<String> entityTable,
  Value<int> entityId,
  Value<DateTime> deletedAt,
  Value<int> rowid,
});

class $$SyncDeletionsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncDeletionsTable> {
  $$SyncDeletionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entityTable => $composableBuilder(
      column: $table.entityTable, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));
}

class $$SyncDeletionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncDeletionsTable> {
  $$SyncDeletionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entityTable => $composableBuilder(
      column: $table.entityTable, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$SyncDeletionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncDeletionsTable> {
  $$SyncDeletionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entityTable => $composableBuilder(
      column: $table.entityTable, builder: (column) => column);

  GeneratedColumn<int> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$SyncDeletionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncDeletionsTable,
    SyncDeletionRow,
    $$SyncDeletionsTableFilterComposer,
    $$SyncDeletionsTableOrderingComposer,
    $$SyncDeletionsTableAnnotationComposer,
    $$SyncDeletionsTableCreateCompanionBuilder,
    $$SyncDeletionsTableUpdateCompanionBuilder,
    (
      SyncDeletionRow,
      BaseReferences<_$AppDatabase, $SyncDeletionsTable, SyncDeletionRow>
    ),
    SyncDeletionRow,
    PrefetchHooks Function()> {
  $$SyncDeletionsTableTableManager(_$AppDatabase db, $SyncDeletionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncDeletionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncDeletionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncDeletionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> entityTable = const Value.absent(),
            Value<int> entityId = const Value.absent(),
            Value<DateTime> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncDeletionsCompanion(
            entityTable: entityTable,
            entityId: entityId,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String entityTable,
            required int entityId,
            required DateTime deletedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncDeletionsCompanion.insert(
            entityTable: entityTable,
            entityId: entityId,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncDeletionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncDeletionsTable,
    SyncDeletionRow,
    $$SyncDeletionsTableFilterComposer,
    $$SyncDeletionsTableOrderingComposer,
    $$SyncDeletionsTableAnnotationComposer,
    $$SyncDeletionsTableCreateCompanionBuilder,
    $$SyncDeletionsTableUpdateCompanionBuilder,
    (
      SyncDeletionRow,
      BaseReferences<_$AppDatabase, $SyncDeletionsTable, SyncDeletionRow>
    ),
    SyncDeletionRow,
    PrefetchHooks Function()>;
typedef $$MediaAssetsTableCreateCompanionBuilder = MediaAssetsCompanion
    Function({
  Value<int> id,
  Value<String> source,
  Value<String> type,
  required String path,
  required String name,
  Value<int?> sizeBytes,
  required DateTime createdAt,
  Value<int?> folderId,
  Value<String?> purpose,
});
typedef $$MediaAssetsTableUpdateCompanionBuilder = MediaAssetsCompanion
    Function({
  Value<int> id,
  Value<String> source,
  Value<String> type,
  Value<String> path,
  Value<String> name,
  Value<int?> sizeBytes,
  Value<DateTime> createdAt,
  Value<int?> folderId,
  Value<String?> purpose,
});

class $$MediaAssetsTableFilterComposer
    extends Composer<_$AppDatabase, $MediaAssetsTable> {
  $$MediaAssetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get path => $composableBuilder(
      column: $table.path, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sizeBytes => $composableBuilder(
      column: $table.sizeBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get folderId => $composableBuilder(
      column: $table.folderId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get purpose => $composableBuilder(
      column: $table.purpose, builder: (column) => ColumnFilters(column));
}

class $$MediaAssetsTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaAssetsTable> {
  $$MediaAssetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get path => $composableBuilder(
      column: $table.path, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
      column: $table.sizeBytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get folderId => $composableBuilder(
      column: $table.folderId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get purpose => $composableBuilder(
      column: $table.purpose, builder: (column) => ColumnOrderings(column));
}

class $$MediaAssetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaAssetsTable> {
  $$MediaAssetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get folderId =>
      $composableBuilder(column: $table.folderId, builder: (column) => column);

  GeneratedColumn<String> get purpose =>
      $composableBuilder(column: $table.purpose, builder: (column) => column);
}

class $$MediaAssetsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MediaAssetsTable,
    MediaAssetRow,
    $$MediaAssetsTableFilterComposer,
    $$MediaAssetsTableOrderingComposer,
    $$MediaAssetsTableAnnotationComposer,
    $$MediaAssetsTableCreateCompanionBuilder,
    $$MediaAssetsTableUpdateCompanionBuilder,
    (
      MediaAssetRow,
      BaseReferences<_$AppDatabase, $MediaAssetsTable, MediaAssetRow>
    ),
    MediaAssetRow,
    PrefetchHooks Function()> {
  $$MediaAssetsTableTableManager(_$AppDatabase db, $MediaAssetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaAssetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaAssetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaAssetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> path = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int?> sizeBytes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int?> folderId = const Value.absent(),
            Value<String?> purpose = const Value.absent(),
          }) =>
              MediaAssetsCompanion(
            id: id,
            source: source,
            type: type,
            path: path,
            name: name,
            sizeBytes: sizeBytes,
            createdAt: createdAt,
            folderId: folderId,
            purpose: purpose,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String> type = const Value.absent(),
            required String path,
            required String name,
            Value<int?> sizeBytes = const Value.absent(),
            required DateTime createdAt,
            Value<int?> folderId = const Value.absent(),
            Value<String?> purpose = const Value.absent(),
          }) =>
              MediaAssetsCompanion.insert(
            id: id,
            source: source,
            type: type,
            path: path,
            name: name,
            sizeBytes: sizeBytes,
            createdAt: createdAt,
            folderId: folderId,
            purpose: purpose,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MediaAssetsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MediaAssetsTable,
    MediaAssetRow,
    $$MediaAssetsTableFilterComposer,
    $$MediaAssetsTableOrderingComposer,
    $$MediaAssetsTableAnnotationComposer,
    $$MediaAssetsTableCreateCompanionBuilder,
    $$MediaAssetsTableUpdateCompanionBuilder,
    (
      MediaAssetRow,
      BaseReferences<_$AppDatabase, $MediaAssetsTable, MediaAssetRow>
    ),
    MediaAssetRow,
    PrefetchHooks Function()>;
typedef $$MediaFoldersTableCreateCompanionBuilder = MediaFoldersCompanion
    Function({
  Value<int> id,
  required String path,
  required String name,
  Value<String?> purpose,
  required DateTime linkedAt,
});
typedef $$MediaFoldersTableUpdateCompanionBuilder = MediaFoldersCompanion
    Function({
  Value<int> id,
  Value<String> path,
  Value<String> name,
  Value<String?> purpose,
  Value<DateTime> linkedAt,
});

class $$MediaFoldersTableFilterComposer
    extends Composer<_$AppDatabase, $MediaFoldersTable> {
  $$MediaFoldersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get path => $composableBuilder(
      column: $table.path, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get purpose => $composableBuilder(
      column: $table.purpose, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get linkedAt => $composableBuilder(
      column: $table.linkedAt, builder: (column) => ColumnFilters(column));
}

class $$MediaFoldersTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaFoldersTable> {
  $$MediaFoldersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get path => $composableBuilder(
      column: $table.path, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get purpose => $composableBuilder(
      column: $table.purpose, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get linkedAt => $composableBuilder(
      column: $table.linkedAt, builder: (column) => ColumnOrderings(column));
}

class $$MediaFoldersTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaFoldersTable> {
  $$MediaFoldersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get purpose =>
      $composableBuilder(column: $table.purpose, builder: (column) => column);

  GeneratedColumn<DateTime> get linkedAt =>
      $composableBuilder(column: $table.linkedAt, builder: (column) => column);
}

class $$MediaFoldersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MediaFoldersTable,
    MediaFolderRow,
    $$MediaFoldersTableFilterComposer,
    $$MediaFoldersTableOrderingComposer,
    $$MediaFoldersTableAnnotationComposer,
    $$MediaFoldersTableCreateCompanionBuilder,
    $$MediaFoldersTableUpdateCompanionBuilder,
    (
      MediaFolderRow,
      BaseReferences<_$AppDatabase, $MediaFoldersTable, MediaFolderRow>
    ),
    MediaFolderRow,
    PrefetchHooks Function()> {
  $$MediaFoldersTableTableManager(_$AppDatabase db, $MediaFoldersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaFoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaFoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaFoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> path = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> purpose = const Value.absent(),
            Value<DateTime> linkedAt = const Value.absent(),
          }) =>
              MediaFoldersCompanion(
            id: id,
            path: path,
            name: name,
            purpose: purpose,
            linkedAt: linkedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String path,
            required String name,
            Value<String?> purpose = const Value.absent(),
            required DateTime linkedAt,
          }) =>
              MediaFoldersCompanion.insert(
            id: id,
            path: path,
            name: name,
            purpose: purpose,
            linkedAt: linkedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MediaFoldersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MediaFoldersTable,
    MediaFolderRow,
    $$MediaFoldersTableFilterComposer,
    $$MediaFoldersTableOrderingComposer,
    $$MediaFoldersTableAnnotationComposer,
    $$MediaFoldersTableCreateCompanionBuilder,
    $$MediaFoldersTableUpdateCompanionBuilder,
    (
      MediaFolderRow,
      BaseReferences<_$AppDatabase, $MediaFoldersTable, MediaFolderRow>
    ),
    MediaFolderRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ItemsTableTableManager get items =>
      $$ItemsTableTableManager(_db, _db.items);
  $$CollectionsTableTableManager get collections =>
      $$CollectionsTableTableManager(_db, _db.collections);
  $$ItemCollectionsTableTableManager get itemCollections =>
      $$ItemCollectionsTableTableManager(_db, _db.itemCollections);
  $$ItemTagsTableTableManager get itemTags =>
      $$ItemTagsTableTableManager(_db, _db.itemTags);
  $$SyncDeletionsTableTableManager get syncDeletions =>
      $$SyncDeletionsTableTableManager(_db, _db.syncDeletions);
  $$MediaAssetsTableTableManager get mediaAssets =>
      $$MediaAssetsTableTableManager(_db, _db.mediaAssets);
  $$MediaFoldersTableTableManager get mediaFolders =>
      $$MediaFoldersTableTableManager(_db, _db.mediaFolders);
}
