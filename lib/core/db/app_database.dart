import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Months extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get year => integer()();
  IntColumn get monthIndex => integer()(); // 0-11

  @override
  List<Set<Column>> get uniqueKeys => [
        {year, monthIndex}
      ];
}

class IncomeItems extends Table {
  TextColumn get id => text()();
  IntColumn get monthId => integer().references(Months, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  RealColumn get amount => real()();
  BoolColumn get done => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class ExpenseItems extends Table {
  TextColumn get id => text()();
  IntColumn get monthId => integer().references(Months, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  RealColumn get amount => real()();
  BoolColumn get done => boolean().withDefault(const Constant(false))();
  IntColumn get dueDay => integer().nullable()(); // 1-31
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class AppSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  RealColumn get dailyWage => real().withDefault(const Constant(0))();
  RealColumn get taxRate => real().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class CalendarNotes extends Table {
  TextColumn get date => text()(); // yyyy-MM-dd
  TextColumn get note => text()();

  @override
  Set<Column> get primaryKey => {date};
}

class Todos extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  BoolColumn get done => boolean().withDefault(const Constant(false))();
  TextColumn get dueDate => text().nullable()(); // yyyy-MM-dd
  TextColumn get createdAt => text()(); // ISO8601
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [Months, IncomeItems, ExpenseItems, AppSettings, CalendarNotes, Todos],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'monthly_planner'));

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  // ── Months ──
  Future<int> monthRowId(int year, int monthIndex) async {
    final existing = await (select(months)
          ..where((m) => m.year.equals(year) & m.monthIndex.equals(monthIndex)))
        .getSingleOrNull();
    if (existing != null) return existing.id;
    return into(months).insert(
        MonthsCompanion.insert(year: year, monthIndex: monthIndex));
  }

  // ── Settings ──
  Stream<AppSetting> watchSettings() {
    return (select(appSettings)..where((s) => s.id.equals(1))).watchSingleOrNull().map(
        (row) => row ?? AppSetting(id: 1, dailyWage: 0, taxRate: 0));
  }

  Future<AppSetting> getSettings() async {
    final row =
        await (select(appSettings)..where((s) => s.id.equals(1))).getSingleOrNull();
    return row ?? AppSetting(id: 1, dailyWage: 0, taxRate: 0);
  }

  Future<void> saveSettings(double dailyWage, double taxRate) {
    return into(appSettings).insertOnConflictUpdate(
        AppSettingsCompanion.insert(
            id: const Value(1),
            dailyWage: Value(dailyWage),
            taxRate: Value(taxRate)));
  }

  // ── Calendar ──
  Stream<List<CalendarNote>> watchAllNotes() => select(calendarNotes).watch();

  Future<void> saveNote(String date, String text) async {
    if (text.trim().isEmpty) {
      await (delete(calendarNotes)..where((n) => n.date.equals(date))).go();
    } else {
      await into(calendarNotes).insertOnConflictUpdate(
          CalendarNotesCompanion.insert(date: date, note: text.trim()));
    }
  }

  // ── Todos ──
  Stream<List<Todo>> watchTodos() {
    return (select(todos)
          ..orderBy([
            (t) => OrderingTerm(expression: t.done),
            (t) => OrderingTerm(expression: t.sortOrder),
          ]))
        .watch();
  }
}
