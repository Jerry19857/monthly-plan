import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monthly_planner/core/db/app_database.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('saveNote upserts and deletes on empty text', () async {
    await db.saveNote('2026-09-07', 'ไปหาหมอ');
    expect((await db.watchAllNotes().first).single.note, 'ไปหาหมอ');
    await db.saveNote('2026-09-07', '   ');
    expect(await db.watchAllNotes().first, isEmpty);
  });

  test('monthRowId is stable per (year, month) and distinct across years',
      () async {
    final a = await db.monthRowId(2026, 0);
    final b = await db.monthRowId(2026, 0);
    final c = await db.monthRowId(2025, 0);
    expect(a, b);
    expect(a, isNot(c));
  });

  test('todo watch orders undone before done', () async {
    await db.into(db.todos).insert(TodosCompanion.insert(
        id: '1', title: 'a', createdAt: 'x', sortOrder: const Value(1)));
    await db.into(db.todos).insert(TodosCompanion.insert(
        id: '2',
        title: 'b',
        createdAt: 'x',
        done: const Value(true),
        sortOrder: const Value(0)));
    final list = await db.watchTodos().first;
    expect(list.map((t) => t.id).toList(), ['1', '2']);
  });
}
