import 'package:flutter_test/flutter_test.dart';
import 'package:zad/data/exercise_data.dart';
import 'package:zad/data/food_seed.dart';
import 'package:zad/data/restaurants_data.dart';

/// القاعدة الغذائية هي ركيزة دقّة التطبيق — هذه الاختبارات تحرسها
/// من أخطاء الإدخال التي لا يلتقطها المحلّل الثابت.
void main() {
  group('سلامة قاعدة الأطعمة', () {
    test('المعرّفات فريدة', () {
      final ids = <String>{};
      for (final f in kFoodSeed) {
        expect(ids.add(f.id), isTrue, reason: 'معرّف مكرر: ${f.id}');
      }
    });

    test('الأسماء والمصادر غير فارغة', () {
      for (final f in kFoodSeed) {
        expect(f.nameAr.trim(), isNotEmpty, reason: f.id);
        expect(f.nameEn.trim(), isNotEmpty, reason: f.id);
        expect(f.source.trim(), isNotEmpty, reason: 'بلا مصدر: ${f.id}');
      }
    });

    test('مستوى الثقة من القيم المعروفة', () {
      const allowed = {'high', 'medium', 'low'};
      for (final f in kFoodSeed) {
        expect(allowed.contains(f.confidence), isTrue,
            reason: 'ثقة غير معروفة "${f.confidence}" في ${f.id}');
      }
    });

    test('القيم الغذائية موجبة وضمن المعقول لكل 100 جرام', () {
      for (final f in kFoodSeed) {
        expect(f.kcalPer100g, greaterThan(0), reason: f.id);
        // أعلى كثافة طاقة ممكنة = دهن صافٍ ≈ 900 سعرة/100غ
        expect(f.kcalPer100g, lessThanOrEqualTo(900), reason: f.id);
        expect(f.proteinPer100g, inInclusiveRange(0, 100), reason: f.id);
        expect(f.carbsPer100g, inInclusiveRange(0, 100), reason: f.id);
        expect(f.fatPer100g, inInclusiveRange(0, 100), reason: f.id);
      }
    });

    test('مجموع الماكروز لا يتجاوز 100 جرام في 100 جرام', () {
      for (final f in kFoodSeed) {
        final sum = f.proteinPer100g + f.carbsPer100g + f.fatPer100g;
        expect(sum, lessThanOrEqualTo(100.5),
            reason: 'ماكروز ${f.id} مجموعها $sum غ في 100غ — مستحيل');
      }
    });

    test('السعرات تتفق مع الماكروز ضمن هامش معقول', () {
      // 4 سعرات للبروتين والكارب، 9 للدهون. نسمح بهامش ±25%
      // (ألياف، كحول سكري، تقريب المصادر).
      for (final f in kFoodSeed) {
        final derived =
            f.proteinPer100g * 4 + f.carbsPer100g * 4 + f.fatPer100g * 9;
        if (derived == 0) continue;
        final ratio = f.kcalPer100g / derived;
        expect(ratio, inInclusiveRange(0.75, 1.25),
            reason: 'سعرات ${f.id} (${f.kcalPer100g}) لا تتفق مع ماكروزها '
                '(المشتق ${derived.round()})');
      }
    });

    test('الحصة النموذجية واقعية ولها تسمية', () {
      for (final f in kFoodSeed) {
        expect(f.typicalServingG, greaterThan(0), reason: f.id);
        expect(f.typicalServingG, lessThanOrEqualTo(1500), reason: f.id);
        expect(f.servingLabelAr.trim(), isNotEmpty, reason: f.id);
        expect(f.servingLabelEn.trim(), isNotEmpty, reason: f.id);
      }
    });

    test('حساب الحصة النموذجية متسق مع قيم 100 جرام', () {
      for (final f in kFoodSeed) {
        final expected = (f.kcalPer100g * f.typicalServingG / 100).round();
        expect(f.typical.calories, expected, reason: f.id);
      }
    });

    test('البحث يجد كل صنف باسمه العربي', () {
      for (final f in kFoodSeed) {
        final hits = searchFoods(f.nameAr);
        expect(hits.any((x) => x.id == f.id), isTrue,
            reason: 'البحث ما لقى ${f.nameAr}');
      }
    });

    test('foodById يطابق القائمة ويرجّع null للمجهول', () {
      for (final f in kFoodSeed) {
        expect(foodById(f.id)?.id, f.id);
      }
      expect(foodById('صنف_وهمي'), isNull);
    });
  });

  group('سلامة قاعدة التمارين', () {
    test('المعرّفات فريدة والحقول مكتملة', () {
      final ids = <String>{};
      for (final e in kExercises) {
        expect(ids.add(e.id), isTrue, reason: 'معرّف مكرر: ${e.id}');
        expect(e.nameAr.trim(), isNotEmpty, reason: e.id);
        expect(e.nameEn.trim(), isNotEmpty, reason: e.id);
      }
    });

    test('المجموعات والتكرارات موجبة', () {
      for (final e in kExercises) {
        expect(e.sets, greaterThan(0), reason: e.id);
        expect(e.reps, greaterThan(0), reason: e.id);
      }
    });

    test('exerciseById يطابق القائمة', () {
      for (final e in kExercises) {
        expect(exerciseById(e.id)?.id, e.id);
      }
      expect(exerciseById('تمرين_وهمي'), isNull);
    });
  });

  group('اقتراحات المطاعم', () {
    test('كل مطعم يشير لصنف موجود فعلاً في القاعدة', () {
      for (final r in kNearbyRestaurants) {
        expect(foodById(r.suggestedDishId), isNotNull,
            reason: "مطعم ${r.nameAr} يقترح صنفاً غير موجود: ${r.suggestedDishId}");
      }
    });
  });
}
