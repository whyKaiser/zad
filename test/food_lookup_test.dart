import 'package:flutter_test/flutter_test.dart';
import 'package:zad/data/food_seed.dart';
import 'package:zad/services/food_lookup.dart';

void main() {
  test('القاعدة: كبسة دجاج ترجّع قيمة موثّقة (مو AI)', () async {
    final r = await FoodLookup().estimate('كبسة دجاج');
    expect(r.source, EstimateSource.database);
    expect(r.calories, 653); // 450g × 145/100 = 652.5 ≈ 653
    expect(r.name, 'كبسة دجاج');
  });

  test('حساب الكمية: نصف صحن كبسة = نصف السعرات', () async {
    final r = await FoodLookup().estimate('كبسة دجاج', grams: 225);
    expect(r.calories, 326); // 225g × 145/100
  });

  test('forGrams يحسب الماكروز بدقة', () {
    final foul = findFood('فول')!;
    final v = foul.forGrams(100);
    expect(v.calories, 110);
    expect(v.macros.protein, 6);
  });

  test('كل أصناف القاعدة لها مصدر وثقة', () {
    for (final f in kFoodSeed) {
      expect(f.source.isNotEmpty, true, reason: '${f.nameAr} بلا مصدر');
      expect(['high', 'medium', 'low'].contains(f.confidence), true);
    }
  });
}
