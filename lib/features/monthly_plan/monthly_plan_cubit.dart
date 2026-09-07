import 'dart:async';

import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/db/app_database.dart';
import '../../core/sheet_api.dart';
import '../../core/thai.dart';
import '../auth/auth_cubit.dart';

enum SyncStatus { idle, busy, ok, err }

class MonthlyPlanState extends Equatable {
  const MonthlyPlanState({
    required this.year,
    required this.monthIndex,
    this.incomes = const [],
    this.expenses = const [],
    this.dailyWage = 0,
    this.taxRate = 0,
    this.prevHasData = false,
    this.sync = SyncStatus.idle,
    this.syncLabel = '',
  });

  final int year;
  final int monthIndex;
  final List<IncomeItem> incomes;
  final List<ExpenseItem> expenses;
  final double dailyWage;
  final double taxRate;
  final bool prevHasData;
  final SyncStatus sync;
  final String syncLabel;

  bool get isEmpty => incomes.isEmpty && expenses.isEmpty;
  double get totalIncome => incomes.fold(0, (s, x) => s + x.amount);
  double get receivedIncome =>
      incomes.where((x) => x.done).fold(0, (s, x) => s + x.amount);
  double get totalExpense => expenses.fold(0, (s, x) => s + x.amount);
  double get paidExpense =>
      expenses.where((x) => x.done).fold(0, (s, x) => s + x.amount);
  double get balance => totalIncome - totalExpense;
  double get outstanding => totalExpense - paidExpense;

  /// Expenses sorted for display: by dueDay asc, nulls last.
  List<ExpenseItem> get sortedExpenses {
    final list = [...expenses];
    list.sort((a, b) {
      if (a.dueDay == null && b.dueDay == null) return 0;
      if (a.dueDay == null) return 1;
      if (b.dueDay == null) return -1;
      return a.dueDay!.compareTo(b.dueDay!);
    });
    return list;
  }

  MonthlyPlanState copyWith({
    int? year,
    int? monthIndex,
    List<IncomeItem>? incomes,
    List<ExpenseItem>? expenses,
    double? dailyWage,
    double? taxRate,
    bool? prevHasData,
    SyncStatus? sync,
    String? syncLabel,
  }) {
    return MonthlyPlanState(
      year: year ?? this.year,
      monthIndex: monthIndex ?? this.monthIndex,
      incomes: incomes ?? this.incomes,
      expenses: expenses ?? this.expenses,
      dailyWage: dailyWage ?? this.dailyWage,
      taxRate: taxRate ?? this.taxRate,
      prevHasData: prevHasData ?? this.prevHasData,
      sync: sync ?? this.sync,
      syncLabel: syncLabel ?? this.syncLabel,
    );
  }

  @override
  List<Object?> get props =>
      [year, monthIndex, incomes, expenses, dailyWage, taxRate, prevHasData, sync, syncLabel];
}

class MonthlyPlanCubit extends Cubit<MonthlyPlanState> {
  MonthlyPlanCubit(this._db, this._api, this._auth)
      : super(MonthlyPlanState(
          year: DateTime.now().year,
          monthIndex: DateTime.now().month - 1,
        )) {
    _settingsSub = _db.watchSettings().listen((s) {
      emit(state.copyWith(dailyWage: s.dailyWage, taxRate: s.taxRate));
    });
    load();
  }

  final AppDatabase _db;
  final SheetApi _api;
  final AuthCubit _auth;
  final Map<String, Timer> _saveTimers = {};
  StreamSubscription? _settingsSub;

  String _sheetName(int monthIndex) => monthsTh[monthIndex];

  Future<void> load() async {
    emit(state.copyWith(sync: SyncStatus.busy, syncLabel: 'กำลังโหลด...'));
    await _refreshFromDb();
    // Local-first: pull the sheet only to seed an empty month (avoids clobbering
    // local edits, and sidesteps the year-collision in the sheet tab name).
    if (state.isEmpty) {
      await _seedFromSheet();
      await _refreshFromDb();
    }
    emit(state.copyWith(sync: SyncStatus.ok, syncLabel: 'พร้อมใช้งาน'));
  }

  Future<void> _refreshFromDb() async {
    final monthId = await _db.monthRowId(state.year, state.monthIndex);
    final incomes = await (_db.select(_db.incomeItems)
          ..where((i) => i.monthId.equals(monthId))
          ..orderBy([(i) => OrderingTerm(expression: i.sortOrder)]))
        .get();
    final expenses = await (_db.select(_db.expenseItems)
          ..where((e) => e.monthId.equals(monthId))
          ..orderBy([(e) => OrderingTerm(expression: e.sortOrder)]))
        .get();
    final prev = shiftMonth(state.year, state.monthIndex, -1);
    final prevId = await _db.monthRowId(prev.year, prev.month);
    final prevIncome = await (_db.select(_db.incomeItems)
          ..where((i) => i.monthId.equals(prevId)))
        .get();
    final prevExpense = await (_db.select(_db.expenseItems)
          ..where((e) => e.monthId.equals(prevId)))
        .get();
    emit(state.copyWith(
      incomes: incomes,
      expenses: expenses,
      prevHasData: prevIncome.isNotEmpty || prevExpense.isNotEmpty,
    ));
  }

  Future<void> _seedFromSheet() async {
    List<List<String>>? rows;
    try {
      rows = await _api.readSheet(_sheetName(state.monthIndex));
    } on UnauthorizedException {
      _auth.lock();
      return;
    }
    if (rows == null || rows.length < 2) return;
    final monthId = await _db.monthRowId(state.year, state.monthIndex);
    await _db.batch((b) {
      for (var i = 1; i < rows!.length; i++) {
        final r = rows[i];
        if (r.isEmpty || r[0].isEmpty) continue;
        final type = r[0];
        final id = r.length > 1 && r[1].isNotEmpty ? r[1] : uid();
        final name = r.length > 2 ? r[2] : '';
        final amount = double.tryParse(r.length > 3 ? r[3] : '') ?? 0;
        final done = r.length > 4 && r[4] == '1';
        if (type == 'income') {
          b.insert(
              _db.incomeItems,
              IncomeItemsCompanion.insert(
                  id: id,
                  monthId: monthId,
                  name: name,
                  amount: amount,
                  done: Value(done),
                  sortOrder: Value(i)),
              mode: InsertMode.insertOrReplace);
        } else if (type == 'expense') {
          final dd = r.length > 5 ? int.tryParse(r[5]) : null;
          b.insert(
              _db.expenseItems,
              ExpenseItemsCompanion.insert(
                  id: id,
                  monthId: monthId,
                  name: name,
                  amount: amount,
                  done: Value(done),
                  dueDay: Value(dd),
                  sortOrder: Value(i)),
              mode: InsertMode.insertOrReplace);
        }
      }
    });
  }

  Future<void> changeMonth(int delta) async {
    final s = shiftMonth(state.year, state.monthIndex, delta);
    emit(state.copyWith(year: s.year, monthIndex: s.month));
    await load();
  }

  Future<void> goToMonth(int year, int monthIndex) async {
    emit(state.copyWith(year: year, monthIndex: monthIndex));
    await load();
  }

  // ── Mutations ──
  Future<void> addIncome(String name, double amount) async {
    final monthId = await _db.monthRowId(state.year, state.monthIndex);
    await _db.into(_db.incomeItems).insert(IncomeItemsCompanion.insert(
        id: uid(),
        monthId: monthId,
        name: name,
        amount: amount,
        sortOrder: Value(DateTime.now().millisecondsSinceEpoch)));
    await _afterChange();
  }

  Future<void> addExpense(String name, double amount, int? dueDay) async {
    final monthId = await _db.monthRowId(state.year, state.monthIndex);
    await _db.into(_db.expenseItems).insert(ExpenseItemsCompanion.insert(
        id: uid(),
        monthId: monthId,
        name: name,
        amount: amount,
        dueDay: Value(dueDay),
        sortOrder: Value(DateTime.now().millisecondsSinceEpoch)));
    await _afterChange();
  }

  Future<void> toggleIncome(String id, bool done) async {
    await (_db.update(_db.incomeItems)..where((i) => i.id.equals(id)))
        .write(IncomeItemsCompanion(done: Value(done)));
    await _afterChange();
  }

  Future<void> toggleExpense(String id, bool done) async {
    await (_db.update(_db.expenseItems)..where((e) => e.id.equals(id)))
        .write(ExpenseItemsCompanion(done: Value(done)));
    await _afterChange();
  }

  Future<void> editIncome(String id, String name, double amount) async {
    await (_db.update(_db.incomeItems)..where((i) => i.id.equals(id)))
        .write(IncomeItemsCompanion(name: Value(name), amount: Value(amount)));
    await _afterChange();
  }

  Future<void> editExpense(
      String id, String name, double amount, int? dueDay) async {
    await (_db.update(_db.expenseItems)..where((e) => e.id.equals(id))).write(
        ExpenseItemsCompanion(
            name: Value(name),
            amount: Value(amount),
            dueDay: Value(dueDay)));
    await _afterChange();
  }

  Future<void> deleteIncome(String id) async {
    await (_db.delete(_db.incomeItems)..where((i) => i.id.equals(id))).go();
    await _afterChange();
  }

  Future<void> deleteExpense(String id) async {
    await (_db.delete(_db.expenseItems)..where((e) => e.id.equals(id))).go();
    await _afterChange();
  }

  /// Replace current month's lists with the previous month's items (legacy:
  /// copy-from-prev replaces, not appends).
  Future<void> copyFromPrev() async {
    final prev = shiftMonth(state.year, state.monthIndex, -1);
    final prevId = await _db.monthRowId(prev.year, prev.month);
    final monthId = await _db.monthRowId(state.year, state.monthIndex);
    final pi =
        await (_db.select(_db.incomeItems)..where((i) => i.monthId.equals(prevId))).get();
    final pe = await (_db.select(_db.expenseItems)
          ..where((e) => e.monthId.equals(prevId)))
        .get();
    await _db.transaction(() async {
      await (_db.delete(_db.incomeItems)..where((i) => i.monthId.equals(monthId))).go();
      await (_db.delete(_db.expenseItems)..where((e) => e.monthId.equals(monthId))).go();
      for (final x in pi) {
        await _db.into(_db.incomeItems).insert(IncomeItemsCompanion.insert(
            id: uid(),
            monthId: monthId,
            name: x.name,
            amount: x.amount,
            sortOrder: Value(x.sortOrder)));
      }
      for (final x in pe) {
        await _db.into(_db.expenseItems).insert(ExpenseItemsCompanion.insert(
            id: uid(),
            monthId: monthId,
            name: x.name,
            amount: x.amount,
            dueDay: Value(x.dueDay),
            sortOrder: Value(x.sortOrder)));
      }
    });
    await _afterChange();
  }

  /// Append current month's items (of [isIncome]) to the target month, sync it
  /// immediately, then navigate there (legacy paste-to-month).
  Future<void> pasteToMonth(bool isIncome, int year, int monthIndex) async {
    final targetId = await _db.monthRowId(year, monthIndex);
    if (isIncome) {
      for (final x in state.incomes) {
        await _db.into(_db.incomeItems).insert(IncomeItemsCompanion.insert(
            id: uid(),
            monthId: targetId,
            name: x.name,
            amount: x.amount,
            sortOrder: Value(DateTime.now().millisecondsSinceEpoch)));
      }
    } else {
      for (final x in state.expenses) {
        await _db.into(_db.expenseItems).insert(ExpenseItemsCompanion.insert(
            id: uid(),
            monthId: targetId,
            name: x.name,
            amount: x.amount,
            dueDay: Value(x.dueDay),
            sortOrder: Value(DateTime.now().millisecondsSinceEpoch)));
      }
    }
    await _syncMonth(year, monthIndex);
    await goToMonth(year, monthIndex);
  }

  Future<void> _afterChange() async {
    await _refreshFromDb();
    _scheduleSave(state.year, state.monthIndex);
  }

  void _scheduleSave(int year, int monthIndex) {
    final key = '$year-$monthIndex';
    _saveTimers[key]?.cancel();
    _saveTimers[key] = Timer(const Duration(milliseconds: 800), () {
      _syncMonth(year, monthIndex);
    });
  }

  Future<void> _syncMonth(int year, int monthIndex) async {
    final isCurrent = year == state.year && monthIndex == state.monthIndex;
    if (isCurrent) {
      emit(state.copyWith(sync: SyncStatus.busy, syncLabel: 'กำลังบันทึก...'));
    }
    try {
      final monthId = await _db.monthRowId(year, monthIndex);
      final incomes = await (_db.select(_db.incomeItems)
            ..where((i) => i.monthId.equals(monthId))).get();
      final expenses = await (_db.select(_db.expenseItems)
            ..where((e) => e.monthId.equals(monthId))).get();
      final rows = <List<Object?>>[
        ['type', 'id', 'name', 'amount', 'done', 'dueDay'],
        for (final x in incomes)
          ['income', x.id, x.name, x.amount, x.done ? '1' : '0', ''],
        for (final x in expenses)
          ['expense', x.id, x.name, x.amount, x.done ? '1' : '0', x.dueDay ?? ''],
      ];
      await _api.writeSheet(monthsTh[monthIndex], rows);
      if (isCurrent) {
        emit(state.copyWith(sync: SyncStatus.ok, syncLabel: 'บันทึกแล้ว'));
      }
    } on UnauthorizedException {
      _auth.lock();
    } catch (_) {
      if (isCurrent) {
        emit(state.copyWith(sync: SyncStatus.err, syncLabel: 'บันทึกไม่สำเร็จ'));
      }
    }
  }

  @override
  Future<void> close() {
    for (final t in _saveTimers.values) {
      t.cancel();
    }
    _settingsSub?.cancel();
    return super.close();
  }
}
