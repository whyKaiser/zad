import '../core/dates.dart';
import '../data/activity_controller.dart';
import '../data/measurements_controller.dart';
import '../data/weight_controller.dart';
import '../models/meal.dart';

/// يبني ملفات CSV من بيانات المستخدم — تصدير يفتح في Excel أو Google Sheets.
/// كل الحقول تُهرَّب بشكل صحيح حتى لا تكسر الأسماء العربية أو الفواصل الجدول.
abstract class DataExportService {
  /// BOM لـ UTF-8 — بدونه Excel على ويندوز يعرض العربي كرموز.
  static const utf8Bom = '﻿';

  /// يهرّب خلية: يلفّها بعلامتَي اقتباس إن حوت فاصلة أو اقتباساً أو سطراً جديداً.
  static String cell(Object? v) {
    final s = v?.toString() ?? '';
    if (s.contains(',') || s.contains('"') || s.contains('\n') || s.contains('\r')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  static String _rows(List<List<Object?>> rows) =>
      rows.map((r) => r.map(cell).join(',')).join('\n');

  /// يوميات الطعام: صف لكل وجبة.
  static String mealsCsv(Map<String, List<Meal>> byDay) {
    final rows = <List<Object?>>[
      ['التاريخ', 'الوقت', 'الوجبة', 'الصنف', 'سعرات', 'بروتين_غ', 'كارب_غ', 'دهون_غ'],
    ];
    final days = byDay.keys.toList()..sort();
    for (final day in days) {
      final meals = [...byDay[day]!]..sort((a, b) => a.time.compareTo(b.time));
      for (final m in meals) {
        rows.add([
          day,
          '${m.time.hour.toString().padLeft(2, '0')}:${m.time.minute.toString().padLeft(2, '0')}',
          m.type.name,
          m.name,
          m.calories,
          m.macros.protein,
          m.macros.carbs,
          m.macros.fat,
        ]);
      }
    }
    return utf8Bom + _rows(rows);
  }

  /// ملخّص يومي: صف لكل يوم بمجاميعه.
  static String dailyTotalsCsv(Map<String, List<Meal>> byDay) {
    final rows = <List<Object?>>[
      ['التاريخ', 'عدد_الأصناف', 'سعرات', 'بروتين_غ', 'كارب_غ', 'دهون_غ'],
    ];
    final days = byDay.keys.toList()..sort();
    for (final day in days) {
      final meals = byDay[day]!;
      rows.add([
        day,
        meals.length,
        meals.fold<int>(0, (a, m) => a + m.calories),
        meals.fold<int>(0, (a, m) => a + m.macros.protein),
        meals.fold<int>(0, (a, m) => a + m.macros.carbs),
        meals.fold<int>(0, (a, m) => a + m.macros.fat),
      ]);
    }
    return utf8Bom + _rows(rows);
  }

  static String weightCsv(List<WeightEntry> entries) {
    final rows = <List<Object?>>[
      ['التاريخ', 'الوزن_كجم'],
    ];
    final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    for (final e in sorted) {
      rows.add([dayKey(e.date), e.kg.toStringAsFixed(1)]);
    }
    return utf8Bom + _rows(rows);
  }

  static String measurementsCsv(List<BodyMeasurement> entries) {
    final rows = <List<Object?>>[
      ['التاريخ', 'صدر_سم', 'خصر_سم', 'ذراع_سم', 'فخذ_سم', 'أرداف_سم', 'رقبة_سم'],
    ];
    final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    for (final m in sorted) {
      rows.add([
        dayKey(m.date),
        m.chest ?? '',
        m.waist ?? '',
        m.arm ?? '',
        m.thigh ?? '',
        m.hip ?? '',
        m.neck ?? '',
      ]);
    }
    return utf8Bom + _rows(rows);
  }

  static String activityCsv(List<ActivityEntry> entries) {
    final rows = <List<Object?>>[
      ['التاريخ', 'النشاط', 'دقائق', 'سعرات_محروقة'],
    ];
    final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    for (final e in sorted) {
      rows.add([dayKey(e.date), e.name, e.minutes, e.calories]);
    }
    return utf8Bom + _rows(rows);
  }
}
