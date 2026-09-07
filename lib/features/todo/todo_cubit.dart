import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/db/app_database.dart';
import '../../core/thai.dart';

class TodoCubit extends Cubit<List<Todo>> {
  TodoCubit(this._db) : super(const []) {
    _sub = _db.watchTodos().listen(emit);
  }

  final AppDatabase _db;
  late final StreamSubscription _sub;

  Future<void> add(String title, {String? dueDate}) {
    return _db.into(_db.todos).insert(TodosCompanion.insert(
        id: uid(),
        title: title,
        dueDate: Value(dueDate),
        createdAt: DateTime.now().toIso8601String(),
        sortOrder: Value(DateTime.now().millisecondsSinceEpoch)));
  }

  Future<void> toggle(String id, bool done) =>
      (_db.update(_db.todos)..where((t) => t.id.equals(id)))
          .write(TodosCompanion(done: Value(done)));

  Future<void> edit(String id, String title) =>
      (_db.update(_db.todos)..where((t) => t.id.equals(id)))
          .write(TodosCompanion(title: Value(title)));

  Future<void> remove(String id) =>
      (_db.delete(_db.todos)..where((t) => t.id.equals(id))).go();

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
