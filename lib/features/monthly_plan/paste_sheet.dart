import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/thai.dart';
import '../../theme.dart';
import 'monthly_plan_cubit.dart';

Future<void> showPasteSheet(BuildContext context, {required bool isIncome}) {
  final cubit = context.read<MonthlyPlanCubit>();
  final s = cubit.state;
  final count = isIncome ? s.incomes.length : s.expenses.length;
  final label = isIncome ? 'รายได้' : 'รายจ่าย';
  final start = shiftMonth(s.year, s.monthIndex, 1);

  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.mantle,
    builder: (sheetContext) {
      var targetYear = start.year;
      var targetMonth = start.month;
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('วาง$label ไปยังเดือน',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                Text('$count รายการจาก ${monthLabel(s.year, s.monthIndex)}',
                    style:
                        const TextStyle(color: AppColors.overlay1, fontSize: 12)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                        onPressed: () => setState(() => targetYear--),
                        icon: const Icon(Icons.chevron_left)),
                    Text('${targetYear + 543}',
                        style: const TextStyle(
                            fontFamily: kMonoFontFamily,
                            fontWeight: FontWeight.w600)),
                    IconButton(
                        onPressed: () => setState(() => targetYear++),
                        icon: const Icon(Icons.chevron_right)),
                  ],
                ),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 2.2,
                  children: List.generate(12, (i) {
                    final sel = i == targetMonth;
                    return OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor:
                            sel ? AppColors.mauve : AppColors.surface0,
                        foregroundColor:
                            sel ? AppColors.crust : AppColors.subtext1,
                      ),
                      onPressed: () => setState(() => targetMonth = i),
                      child: Text(monthsTh[i].substring(0, 3)),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const Text('ยกเลิก')),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        await cubit.pasteToMonth(
                            isIncome, targetYear, targetMonth);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  '✓ วางรายการไปยัง ${monthLabel(targetYear, targetMonth)} แล้ว')));
                        }
                      },
                      child: const Text('วางรายการ'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
