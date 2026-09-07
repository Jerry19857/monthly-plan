import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/db/app_database.dart';
import '../../theme.dart';
import 'todo_cubit.dart';

class TodoPage extends StatelessWidget {
  const TodoPage({super.key});

  Future<void> _add(BuildContext context) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.mantle,
        title: const Text('เพิ่มงาน'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'ต้องทำอะไร...'),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('เพิ่ม')),
        ],
      ),
    );
    if (text != null && text.trim().isNotEmpty && context.mounted) {
      await context.read<TodoCubit>().add(text.trim());
    }
  }

  Future<void> _edit(BuildContext context, Todo t) async {
    final controller = TextEditingController(text: t.title);
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.mantle,
        title: const Text('แก้ไขงาน'),
        content: TextField(
            controller: controller,
            autofocus: true,
            onSubmitted: (v) => Navigator.pop(context, v)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('บันทึก')),
        ],
      ),
    );
    if (text != null && text.trim().isNotEmpty && context.mounted) {
      await context.read<TodoCubit>().edit(t.id, text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('งานที่ต้องทำ'), backgroundColor: AppColors.mantle),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.mauve,
        onPressed: () => _add(context),
        child: const Icon(Icons.add, color: AppColors.crust),
      ),
      body: BlocBuilder<TodoCubit, List<Todo>>(
        builder: (context, todos) {
          if (todos.isEmpty) {
            return const Center(
                child: Text('ยังไม่มีงาน',
                    style: TextStyle(color: AppColors.overlay0)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: todos.length,
            itemBuilder: (context, i) {
              final t = todos[i];
              return Dismissible(
                key: ValueKey(t.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: AppColors.red,
                  child: const Icon(Icons.delete, color: AppColors.crust),
                ),
                onDismissed: (_) => context.read<TodoCubit>().remove(t.id),
                child: Card(
                  color: AppColors.surface0,
                  child: ListTile(
                    leading: Checkbox(
                      value: t.done,
                      activeColor: AppColors.green,
                      onChanged: (v) =>
                          context.read<TodoCubit>().toggle(t.id, v ?? false),
                    ),
                    title: Text(t.title,
                        style: TextStyle(
                          decoration:
                              t.done ? TextDecoration.lineThrough : null,
                          color: t.done ? AppColors.overlay0 : AppColors.text,
                        )),
                    onTap: () => _edit(context, t),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
