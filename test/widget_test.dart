import 'package:flutter_test/flutter_test.dart';

import 'package:monthly_planner/core/thai.dart';

void main() {
  test('shiftMonth wraps years', () {
    expect(shiftMonth(2026, 0, -1), (year: 2025, month: 11));
    expect(shiftMonth(2026, 11, 1), (year: 2027, month: 0));
    expect(shiftMonth(2026, 5, 3), (year: 2026, month: 8));
  });

  test('fmtBaht formats thousands', () {
    expect(fmtBaht(0), '฿0');
    expect(fmtBaht(1234567), '฿1,234,567');
    expect(fmtBaht(1234.5), '฿1,234.5');
    expect(fmtBaht(-800), '-฿800');
  });

  test('uid is unique-ish', () {
    final a = uid();
    final b = uid();
    expect(a, isNot(equals(b)));
  });
}
