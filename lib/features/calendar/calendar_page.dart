import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../theme.dart';
import 'calendar_cubit.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();

  Future<void> _editNote() async {
    final cubit = context.read<CalendarCubit>();
    final controller =
        TextEditingController(text: cubit.state.noteFor(_selected));
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.mantle,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('บันทึกวันที่ ${_selected.day}/${_selected.month}/${_selected.year + 543}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 5,
              minLines: 3,
              decoration: const InputDecoration(
                  hintText: 'วันนี้ต้องทำอะไรบ้าง...',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('บันทึก'),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      await cubit.saveNote(_selected, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('ปฏิทิน'), backgroundColor: AppColors.mantle),
      body: BlocBuilder<CalendarCubit, CalendarState>(
        builder: (context, state) {
          final note = state.noteFor(_selected);
          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2020),
                lastDay: DateTime.utc(2035, 12, 31),
                focusedDay: _focused,
                selectedDayPredicate: (d) => isSameDay(d, _selected),
                onDaySelected: (sel, foc) =>
                    setState(() { _selected = sel; _focused = foc; }),
                eventLoader: (day) =>
                    state.notes.containsKey(dateKey(day)) ? const [1] : const [],
                calendarStyle: const CalendarStyle(
                  markerDecoration: BoxDecoration(
                      color: AppColors.mauve, shape: BoxShape.circle),
                  todayDecoration: BoxDecoration(
                      color: AppColors.surface1, shape: BoxShape.circle),
                  selectedDecoration: BoxDecoration(
                      color: AppColors.mauve, shape: BoxShape.circle),
                ),
                headerStyle: const HeaderStyle(formatButtonVisible: false),
              ),
              const Divider(height: 1, color: AppColors.surface0),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      color: AppColors.mantle,
                      child: ListTile(
                        title: Text(note.isEmpty ? 'ยังไม่มีบันทึก' : note,
                            style: TextStyle(
                                color: note.isEmpty
                                    ? AppColors.overlay0
                                    : AppColors.text)),
                        trailing: const Icon(Icons.edit, color: AppColors.blue),
                        onTap: _editNote,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.mauve,
        onPressed: _editNote,
        child: const Icon(Icons.edit, color: AppColors.crust),
      ),
    );
  }
}
