import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/db/app_database.dart';

String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class CalendarState {
  const CalendarState(this.notes);
  final Map<String, String> notes; // dateKey -> text
  String noteFor(DateTime d) => notes[dateKey(d)] ?? '';
}

class CalendarCubit extends Cubit<CalendarState> {
  CalendarCubit(this._db) : super(const CalendarState({})) {
    _sub = _db.watchAllNotes().listen((rows) {
      emit(CalendarState({for (final r in rows) r.date: r.note}));
    });
  }

  final AppDatabase _db;
  late final StreamSubscription _sub;

  Future<void> saveNote(DateTime day, String text) =>
      _db.saveNote(dateKey(day), text);

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
