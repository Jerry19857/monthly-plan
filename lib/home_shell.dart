import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/db/app_database.dart';
import 'features/calendar/calendar_cubit.dart';
import 'features/calendar/calendar_page.dart';
import 'features/monthly_plan/monthly_plan_page.dart';
import 'features/settings/settings_page.dart';
import 'features/todo/todo_cubit.dart';
import 'features/todo/todo_page.dart';
import 'theme.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final db = context.read<AppDatabase>();
    final pages = [
      const MonthlyPlanPage(),
      BlocProvider(create: (_) => CalendarCubit(db), child: const CalendarPage()),
      BlocProvider(create: (_) => TodoCubit(db), child: const TodoPage()),
      const SettingsPage(),
    ];
    return Scaffold(
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.mantle,
        indicatorColor: AppColors.surface1,
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: 'วางแผน'),
          NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(Icons.calendar_today),
              label: 'ปฏิทิน'),
          NavigationDestination(
              icon: Icon(Icons.checklist_outlined),
              selectedIcon: Icon(Icons.checklist),
              label: 'งานที่ต้องทำ'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'ตั้งค่า'),
        ],
      ),
    );
  }
}
