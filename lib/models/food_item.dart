import 'package:flutter/foundation.dart';

import 'meal.dart';

/// صنف بقاعدة الأطعمة. القيم **لكل 100 جرام** (الأثبت علمياً)،
/// مع حصة نموذجية. المستخدم يعدّل الكمية والتطبيق يحسب — يضمن الدقة لأي حصة.
@immutable
class FoodItem {
  final String id;
  final String nameAr;
  final String nameEn;

  // القيم لكل 100 جرام
  final int kcalPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;

  // الحصة النموذجية
  final int typicalServingG;
  final String servingLabelAr; // مثل: صحن، ساندويتش، قطعة
  final String servingLabelEn;

  // التوثيق
  final String source;     // من وين القيمة
  final String confidence; // high / medium / low

  const FoodItem({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.kcalPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    required this.typicalServingG,
    required this.servingLabelAr,
    required this.servingLabelEn,
    required this.source,
    this.confidence = 'medium',
  });

  /// يحسب القيم لكمية معيّنة بالجرام.
  ({int calories, Macros macros}) forGrams(num grams) {
    final f = grams / 100.0;
    return (
      calories: (kcalPer100g * f).round(),
      macros: Macros(
        protein: (proteinPer100g * f).round(),
        carbs: (carbsPer100g * f).round(),
        fat: (fatPer100g * f).round(),
      ),
    );
  }

  /// القيم للحصة النموذجية.
  ({int calories, Macros macros}) get typical => forGrams(typicalServingG);
}
