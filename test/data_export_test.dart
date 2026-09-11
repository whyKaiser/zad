import 'package:flutter_test/flutter_test.dart';
import 'package:zad/data/activity_controller.dart';
import 'package:zad/data/measurements_controller.dart';
import 'package:zad/data/weight_controller.dart';
import 'package:zad/models/meal.dart';
import 'package:zad/services/data_export_service.dart';

Meal _meal(String name, {int cal = 300, MealType type = MealType.lunch, int hour = 13}) => Meal(
      id: name,
      name: name,
      calories: cal,
      macros: const Macros(protein: 20, carbs: 30, fat: 10),
      time: DateTime(2026, 3, 4, hour, 5),
      type: type,
    );

void main() {
  group('تهريب خلايا CSV', () {
    test('اسم فيه فاصلة يُلفّ باقتباس', () {
      expect(DataExportService.cell('كبسة, دجاج'), '"كبسة, دجاج"');
    });

    test('اقتباس داخل النص يُضاعف', () {
      expect(DataExportService.cell('برجر "دبل"'), '"برجر ""دبل"""');
    });

    test('سطر جديد يُلفّ', () {
      expect(DataExportService.cell('سطر\nثاني'), '"سطر\nثاني"');
    });

    test('نص عادي يبقى كما هو', () {
      expect(DataExportService.cell('كبسة'), 'كبسة');
      expect(DataExportService.cell(450), '450');
      expect(DataExportService.cell(null), '');
    });
  });

  group('تصدير اليوميات', () {
    final byDay = {
      '2026-03-04': [_meal('كبسة', cal: 700), _meal('تمر', cal: 100, hour: 9)],
      '2026-03-03': [_meal('شاورما', cal: 520)],
    };

    test('يبدأ بـ BOM حتى يقرأ Excel العربي صحيحاً', () {
      expect(DataExportService.mealsCsv(byDay).startsWith(DataExportService.utf8Bom), isTrue);
    });

    test('صف لكل وجبة + ترويسة', () {
      final lines = DataExportService.mealsCsv(byDay).split('\n');
      expect(lines.length, 4); // ترويسة + 3 وجبات
      expect(lines.first, contains('سعرات'));
    });

    test('الأيام مرتّبة تصاعدياً والوجبات بالوقت', () {
      final lines = DataExportService.mealsCsv(byDay).split('\n');
      expect(lines[1], contains('2026-03-03'));
      expect(lines[2], contains('تمر')); // 09:05 قبل 13:05
      expect(lines[3], contains('كبسة'));
    });

    test('الملخّص اليومي يجمع صحيحاً', () {
      final lines = DataExportService.dailyTotalsCsv(byDay).split('\n');
      final march4 = lines.firstWhere((l) => l.contains('2026-03-04'));
      expect(march4, contains('800')); // 700 + 100
      expect(march4, contains('40')); // بروتين 20 + 20
    });

    test('بيانات فارغة تنتج ترويسة فقط بلا انهيار', () {
      final out = DataExportService.mealsCsv({});
      expect(out.split('\n').length, 1);
    });
  });

  test('تصدير الوزن مرتّب ومحدّد بخانة عشرية', () {
    final csv = DataExportService.weightCsv([
      WeightEntry(DateTime(2026, 3, 5), 80.456),
      WeightEntry(DateTime(2026, 3, 1), 82.0),
    ]);
    final lines = csv.split('\n');
    expect(lines[1], contains('2026-03-01'));
    expect(lines[1], contains('82.0'));
    expect(lines[2], contains('80.5'));
  });

  test('القياسات الناقصة تُترك فارغة لا صفراً', () {
    final csv = DataExportService.measurementsCsv([
      BodyMeasurement(date: DateTime(2026, 3, 1), waist: 85),
    ]);
    final row = csv.split('\n')[1];
    expect(row, contains('85'));
    expect(row.split(',').where((f) => f.isEmpty).length, greaterThan(3));
  });

  test('تصدير النشاط يشمل الدقائق والسعرات', () {
    final csv = DataExportService.activityCsv([
      ActivityEntry(
          id: 'run', name: 'جري', minutes: 30, calories: 250, date: DateTime(2026, 3, 2)),
    ]);
    expect(csv, contains('جري'));
    expect(csv, contains('30'));
    expect(csv, contains('250'));
  });
}
