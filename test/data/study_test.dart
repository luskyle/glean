import 'package:flutter_test/flutter_test.dart';
import 'package:shiyi/data/database/database.dart';
import 'package:shiyi/data/dictionary/dictionary_service.dart';
import 'package:shiyi/data/dictionary/language_catalog.dart';
import 'package:shiyi/data/repositories/item_repository.dart';

void main() {
  late AppDatabase db;
  late ItemRepository repo;

  setUp(() {
    db = AppDatabase.forTesting();
    repo = ItemRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('语言包分级：日语/英语免费，其余 Pro 解锁', () {
    expect(LanguageCatalog.isFree('ja'), isTrue);
    expect(LanguageCatalog.isFree('en'), isTrue);
    expect(LanguageCatalog.isFree('ko'), isFalse);

    expect(LanguageCatalog.unlocked('ko', isPro: false), isFalse);
    expect(LanguageCatalog.unlocked('ko', isPro: true), isTrue);
    expect(LanguageCatalog.unlocked('ja', isPro: false), isTrue);
  });

  test('词库导入支持多语言；unstudiedWords 返回未学词', () async {
    // 模拟导入韩语示例包
    await repo.importDictionaryEntries(const [
      DictionaryEntry(
          lang: 'ko', headword: '사랑', reading: 'sarang', meaning: '爱'),
      DictionaryEntry(
          lang: 'ko', headword: '시간', reading: 'sigan', meaning: '时间'),
      DictionaryEntry(
          lang: 'en', headword: 'apple', reading: '/ˈæpəl/', meaning: '苹果'),
    ]);

    final koWords =
        await (db.select(db.words)..where((t) => t.lang.equals('ko'))).get();
    expect(koWords, hasLength(2));

    final pending = await repo.unstudiedWords(lang: 'ko');
    expect(pending, hasLength(2));
  });

  test('学习成卡：wordId 关联 + 未学列表排除已学', () async {
    await repo.importDictionaryEntries(const [
      DictionaryEntry(
          lang: 'ko', headword: '사랑', reading: 'sarang', meaning: '爱'),
    ]);
    final pending = await repo.unstudiedWords(lang: 'ko');
    final word = pending.first;

    final itemId = await repo.createManualCard(
      prompt: word.headword,
      answer: '爱',
      kind: 'word',
      lang: 'ko',
      wordId: word.id,
      source: 'study',
    );

    final item = await (db.select(db.items)..where((t) => t.id.equals(itemId)))
        .getSingle();
    final card = await (db.select(db.cards)
          ..where((t) => t.id.equals(item.cardId!)))
        .getSingle();
    expect(card.wordId, word.id); // 关联官方词条
    expect(card.lang, 'ko');

    // 已学词不再出现在未学列表
    final remaining = await repo.unstudiedWords(lang: 'ko');
    expect(remaining, isEmpty);
  });
}
