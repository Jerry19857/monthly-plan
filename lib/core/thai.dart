import 'dart:math';

/// Thai month names — index 0 = January. These are ALSO the Google Sheet tab
/// names for the monthly-plan sync (ported from legacy/app.js:4-5).
const monthsTh = <String>[
  'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
  'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
];

const settingsSheetName = 'ตั้งค่า';

/// Buddhist-era label, e.g. "กันยายน 2568" (legacy showed year + 543).
String monthLabel(int year, int monthIndex) =>
    '${monthsTh[monthIndex]} ${year + 543}';

final _rand = Random();

/// Port of legacy uid(): timestamp base36 + 4 random base36 chars.
String uid() {
  final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
  final r = _rand.nextDouble().toString().substring(2);
  final tail = BigInt.parse(r).toRadixString(36).padLeft(4, '0');
  return ts + tail.substring(tail.length - 4);
}

String fmtBaht(num n) {
  final v = n.abs();
  final whole = v.truncate();
  final frac = v - whole;
  final s = whole.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  final sign = n < 0 ? '-' : '';
  if (frac == 0) return '$sign฿$s';
  final fracStr = frac.toStringAsFixed(2).substring(2).replaceAll(RegExp(r'0+$'), '');
  return '$sign฿$s.$fracStr';
}

/// (year, monthIndex) shifted by delta months.
({int year, int month}) shiftMonth(int year, int monthIndex, int delta) {
  var m = monthIndex + delta;
  var y = year;
  while (m < 0) {
    m += 12;
    y--;
  }
  while (m > 11) {
    m -= 12;
    y++;
  }
  return (year: y, month: m);
}
