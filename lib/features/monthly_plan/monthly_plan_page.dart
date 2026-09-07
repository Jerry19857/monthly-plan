import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/db/app_database.dart';
import '../../core/thai.dart';
import '../../theme.dart';
import 'monthly_plan_cubit.dart';
import 'paste_sheet.dart';

class MonthlyPlanPage extends StatelessWidget {
  const MonthlyPlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MonthlyPlanCubit, MonthlyPlanState>(
      builder: (context, state) {
        final cubit = context.read<MonthlyPlanCubit>();
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _Header(state: state),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _SummaryCard(state: state),
                      if (state.isEmpty && state.prevHasData)
                        _Banner(
                          label: '📋 คัดลอกรายการจากเดือนก่อนหน้า',
                          onTap: cubit.copyFromPrev,
                        ),
                      const SizedBox(height: 16),
                      _IncomeCard(state: state),
                      const SizedBox(height: 16),
                      _ExpenseCard(state: state),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state});
  final MonthlyPlanState state;

  Color get _dotColor => switch (state.sync) {
        SyncStatus.ok => AppColors.green,
        SyncStatus.busy => AppColors.yellow,
        SyncStatus.err => AppColors.red,
        SyncStatus.idle => AppColors.overlay0,
      };

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MonthlyPlanCubit>();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(
        color: AppColors.mantle,
        border: Border(bottom: BorderSide(color: AppColors.surface0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('💰 วางแผนการเงิน',
                  style: TextStyle(
                      color: AppColors.mauve,
                      fontSize: 17,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: _dotColor, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(state.syncLabel,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.overlay1)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton(
                  onPressed: () => cubit.changeMonth(-1),
                  icon: const Icon(Icons.chevron_left)),
              Expanded(
                child: Text(
                  monthLabel(state.year, state.monthIndex),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: kMonoFontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                ),
              ),
              IconButton(
                  onPressed: () => cubit.changeMonth(1),
                  icon: const Icon(Icons.chevron_right)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.state});
  final MonthlyPlanState state;

  @override
  Widget build(BuildContext context) {
    final outstanding = state.outstanding;
    final te = state.totalExpense;
    String badge;
    Color badgeColor;
    Color balColor;
    if (outstanding <= 0 && te > 0) {
      badge = '✓ จ่ายครบแล้ว';
      badgeColor = AppColors.green;
      balColor = AppColors.green;
    } else if (outstanding > 0) {
      badge = 'ค้างจ่าย ${fmtBaht(outstanding)}';
      badgeColor = AppColors.peach;
      balColor = state.balance >= 0 ? AppColors.yellow : AppColors.red;
    } else {
      badge = '—';
      badgeColor = AppColors.overlay1;
      balColor = AppColors.subtext1;
    }
    return Card(
      color: AppColors.mantle,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('สรุปภาพรวม',
                style: TextStyle(
                    color: AppColors.overlay1,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _Stat(
                        label: 'รายได้คาดการณ์',
                        value: fmtBaht(state.totalIncome),
                        sub: 'ได้รับแล้ว ${fmtBaht(state.receivedIncome)}',
                        color: AppColors.green)),
                const SizedBox(width: 10),
                Expanded(
                    child: _Stat(
                        label: 'รายจ่ายทั้งหมด',
                        value: fmtBaht(state.totalExpense),
                        sub: 'จ่ายแล้ว ${fmtBaht(state.paidExpense)}',
                        color: AppColors.maroon)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppColors.surface0,
                  borderRadius: BorderRadius.circular(AppRadius.lg)),
              child: Row(
                children: [
                  const Text('ยอดคงเหลือคาดการณ์',
                      style: TextStyle(color: AppColors.subtext0)),
                  const Spacer(),
                  Text(fmtBaht(state.balance),
                      style: TextStyle(
                          fontFamily: kMonoFontFamily,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: balColor)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(badge,
                  style: TextStyle(
                      color: badgeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(
      {required this.label,
      required this.value,
      required this.sub,
      required this.color});
  final String label, value, sub;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppColors.surface0,
          borderRadius: BorderRadius.circular(AppRadius.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.overlay1)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontFamily: kMonoFontFamily,
                  fontWeight: FontWeight.w600,
                  color: color)),
          Text(sub,
              style: const TextStyle(
                  fontFamily: kMonoFontFamily,
                  fontSize: 11,
                  color: AppColors.subtext0)),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: OutlinedButton(onPressed: onTap, child: Text(label)),
    );
  }
}

class _IncomeCard extends StatefulWidget {
  const _IncomeCard({required this.state});
  final MonthlyPlanState state;

  @override
  State<_IncomeCard> createState() => _IncomeCardState();
}

class _IncomeCardState extends State<_IncomeCard> {
  bool _calcMode = false;
  bool _settingsOpen = false;
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _days = TextEditingController();
  final _wage = TextEditingController();
  final _tax = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _amount, _days, _wage, _tax]) {
      c.dispose();
    }
    super.dispose();
  }

  double get _net {
    final d = double.tryParse(_days.text) ?? 0;
    final gross = d * widget.state.dailyWage;
    return gross - gross * (widget.state.taxRate / 100);
  }

  Future<void> _add() async {
    final cubit = context.read<MonthlyPlanCubit>();
    final name = _name.text.trim();
    if (name.isEmpty) return;
    if (_calcMode) {
      final d = double.tryParse(_days.text) ?? 0;
      if (d == 0) return;
      if (widget.state.dailyWage == 0) {
        _openSettings();
        return;
      }
      await cubit.addIncome(name, _net);
      _days.clear();
    } else {
      final a = double.tryParse(_amount.text) ?? 0;
      if (a == 0) return;
      await cubit.addIncome(name, a);
      _amount.clear();
    }
    _name.clear();
    setState(() {});
  }

  Future<void> _saveProfile() async {
    await context.read<AppDatabase>().saveSettings(
        double.tryParse(_wage.text) ?? 0, double.tryParse(_tax.text) ?? 0);
    setState(() => _settingsOpen = false);
  }

  void _openSettings() {
    final s = widget.state;
    _wage.text = s.dailyWage == 0 ? '' : _trim(s.dailyWage);
    _tax.text = s.taxRate == 0 ? '' : _trim(s.taxRate);
    setState(() => _settingsOpen = true);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return Card(
      color: AppColors.mantle,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text('รายได้เดือนนี้',
                    style: TextStyle(
                        color: AppColors.overlay1,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1)),
                const Spacer(),
                TextButton.icon(
                  onPressed: s.incomes.isEmpty
                      ? null
                      : () => showPasteSheet(context, isIncome: true),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('คัดลอกรายได้'),
                ),
              ],
            ),
            TextButton(
              onPressed: () => _settingsOpen
                  ? setState(() => _settingsOpen = false)
                  : _openSettings(),
              child: Text(_settingsOpen
                  ? '▴ ค่าแรงต่อวัน & ภาษี'
                  : '▾ ค่าแรงต่อวัน & ภาษี'),
            ),
            if (_settingsOpen) ...[
              Row(children: [
                Expanded(
                    child: TextField(
                        controller: _wage,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'ค่าแรง/วัน'))),
                const SizedBox(width: 10),
                Expanded(
                    child: TextField(
                        controller: _tax,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'ภาษี %'))),
              ]),
              const SizedBox(height: 8),
              FilledButton(
                  onPressed: _saveProfile, child: const Text('บันทึก')),
              const SizedBox(height: 8),
            ],
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('กรอกเอง')),
                ButtonSegment(value: true, label: Text('คำนวณจากวันทำงาน')),
              ],
              selected: {_calcMode},
              onSelectionChanged: (v) => setState(() => _calcMode = v.first),
            ),
            const SizedBox(height: 10),
            TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'ชื่อรายการ')),
            const SizedBox(height: 8),
            if (_calcMode) ...[
              TextField(
                  controller: _days,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'จำนวนวัน')),
              if ((double.tryParse(_days.text) ?? 0) > 0 && s.dailyWage > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${_days.text} วัน × ${fmtBaht(s.dailyWage)} − ภาษี ${_trim(s.taxRate)}% = ${fmtBaht(_net)}',
                    style: const TextStyle(
                        color: AppColors.teal,
                        fontFamily: kMonoFontFamily,
                        fontSize: 12),
                  ),
                ),
            ] else
              TextField(
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'จำนวน (บาท)')),
            const SizedBox(height: 8),
            FilledButton(onPressed: _add, child: const Text('+ เพิ่มรายได้')),
            const SizedBox(height: 10),
            if (s.incomes.isEmpty)
              const _Empty('ยังไม่มีรายการรายได้')
            else
              ...s.incomes.map((x) => _ItemRow(
                    name: x.name,
                    amount: x.amount,
                    done: x.done,
                    color: AppColors.green,
                    onToggle: (v) => context
                        .read<MonthlyPlanCubit>()
                        .toggleIncome(x.id, v),
                    onDelete: () =>
                        context.read<MonthlyPlanCubit>().deleteIncome(x.id),
                    onEdit: () => _editIncome(x),
                  )),
          ],
        ),
      ),
    );
  }

  String _trim(double v) =>
      v == v.truncate() ? v.truncate().toString() : v.toString();

  Future<void> _editIncome(IncomeItem x) async {
    final r = await _editDialog(context, x.name, x.amount, null, showDue: false);
    if (r != null && mounted) {
      await context
          .read<MonthlyPlanCubit>()
          .editIncome(x.id, r.name, r.amount);
    }
  }
}

class _ExpenseCard extends StatefulWidget {
  const _ExpenseCard({required this.state});
  final MonthlyPlanState state;

  @override
  State<_ExpenseCard> createState() => _ExpenseCardState();
}

class _ExpenseCardState extends State<_ExpenseCard> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _due = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _due.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final name = _name.text.trim();
    final a = double.tryParse(_amount.text) ?? 0;
    if (name.isEmpty || a == 0) return;
    final dd = int.tryParse(_due.text);
    await context.read<MonthlyPlanCubit>().addExpense(name, a, dd);
    _name.clear();
    _amount.clear();
    _due.clear();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return Card(
      color: AppColors.mantle,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text('รายจ่ายเดือนนี้',
                    style: TextStyle(
                        color: AppColors.overlay1,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1)),
                const Spacer(),
                TextButton.icon(
                  onPressed: s.expenses.isEmpty
                      ? null
                      : () => showPasteSheet(context, isIncome: false),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('คัดลอกรายจ่าย'),
                ),
              ],
            ),
            TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'ชื่อรายการ')),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: _amount,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'จำนวน (บาท)'))),
              const SizedBox(width: 10),
              SizedBox(
                  width: 110,
                  child: TextField(
                      controller: _due,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'วันจ่าย', hintText: '1-31'))),
            ]),
            const SizedBox(height: 8),
            FilledButton(onPressed: _add, child: const Text('+ เพิ่มรายจ่าย')),
            const SizedBox(height: 10),
            if (s.expenses.isEmpty)
              const _Empty('ยังไม่มีรายการรายจ่าย')
            else
              ...s.sortedExpenses.map((x) => _ItemRow(
                    name: x.name,
                    amount: x.amount,
                    done: x.done,
                    due: x.dueDay,
                    color: AppColors.maroon,
                    onToggle: (v) => context
                        .read<MonthlyPlanCubit>()
                        .toggleExpense(x.id, v),
                    onDelete: () =>
                        context.read<MonthlyPlanCubit>().deleteExpense(x.id),
                    onEdit: () => _editExpense(x),
                  )),
          ],
        ),
      ),
    );
  }

  Future<void> _editExpense(ExpenseItem x) async {
    final r = await _editDialog(context, x.name, x.amount, x.dueDay, showDue: true);
    if (r != null && mounted) {
      await context
          .read<MonthlyPlanCubit>()
          .editExpense(x.id, r.name, r.amount, r.due);
    }
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.name,
    required this.amount,
    required this.done,
    required this.color,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    this.due,
  });

  final String name;
  final double amount;
  final bool done;
  final int? due;
  final Color color;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: AppColors.surface0,
          borderRadius: BorderRadius.circular(AppRadius.r)),
      child: Row(
        children: [
          Checkbox(
              value: done,
              activeColor: color,
              onChanged: (v) => onToggle(v ?? false)),
          if (due != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text('วัน $due',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.overlay1)),
            ),
          Expanded(
            child: Text(name,
                style: TextStyle(
                  decoration: done ? TextDecoration.lineThrough : null,
                  color: done ? AppColors.overlay0 : AppColors.text,
                )),
          ),
          Text(fmtBaht(amount),
              style: TextStyle(
                  fontFamily: kMonoFontFamily,
                  color: color,
                  fontWeight: FontWeight.w500)),
          IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, size: 18, color: AppColors.overlay0)),
          IconButton(
              onPressed: onDelete,
              icon:
                  const Icon(Icons.close, size: 18, color: AppColors.overlay0)),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
            child: Text(text,
                style: const TextStyle(color: AppColors.overlay0))),
      );
}

class _EditResult {
  _EditResult(this.name, this.amount, this.due);
  final String name;
  final double amount;
  final int? due;
}

Future<_EditResult?> _editDialog(
    BuildContext context, String name, double amount, int? due,
    {required bool showDue}) {
  final n = TextEditingController(text: name);
  final a = TextEditingController(
      text: amount == amount.truncate()
          ? amount.truncate().toString()
          : amount.toString());
  final d = TextEditingController(text: due?.toString() ?? '');
  final hasDue = showDue;
  return showDialog<_EditResult>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.mantle,
      title: const Text('แก้ไขรายการ'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
              controller: n,
              decoration: const InputDecoration(labelText: 'ชื่อ')),
          TextField(
              controller: a,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'จำนวน')),
          if (hasDue)
            TextField(
                controller: d,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'วันจ่าย (ไม่บังคับ)')),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
        FilledButton(
          onPressed: () {
            final name = n.text.trim();
            final amt = double.tryParse(a.text) ?? 0;
            if (name.isEmpty || amt == 0) return;
            Navigator.pop(
                context, _EditResult(name, amt, int.tryParse(d.text)));
          },
          child: const Text('บันทึก'),
        ),
      ],
    ),
  );
}
