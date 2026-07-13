import '../data/food_seed.dart';
import '../models/meal.dart';
import 'ai_router.dart';

/// مصدر التقدير — يحدّد مستوى الثقة المعروض للمستخدم.
enum EstimateSource { database, ai }

class FoodResult {
  final String name;
  final int calories;
  final Macros macros;
  final EstimateSource source;
  final String confidence; // high / medium / low
  final String detail; // مصدر القاعدة أو ملاحظة الـ AI

  FoodResult({
    required this.name,
    required this.calories,
    required this.macros,
    required this.source,
    required this.confidence,
    required this.detail,
  });

  bool get isApproximate => source == EstimateSource.ai || confidence == 'low';
}

/// الزبدة: القاعدة أولاً (قيم موثّقة دقيقة)، وإلا الـ AI (تقديري).
class FoodLookup {
  final AiRouter ai;
  FoodLookup({AiRouter? ai}) : ai = ai ?? AiRouter();

  Future<FoodResult> estimate(String query, {num? grams}) async {
    // 1) قاعدة البذرة الموثّقة
    final item = findFood(query);
    if (item != null) {
      final v = grams != null ? item.forGrams(grams) : item.typical;
      return FoodResult(
        name: item.nameAr,
        calories: v.calories,
        macros: v.macros,
        source: EstimateSource.database,
        confidence: item.confidence,
        detail: item.source,
      );
    }

    // 2) احتياطي: الذكاء (يُوسم تقديري)
    final est = await ai.estimateFromText(query);
    return FoodResult(
      name: est.name,
      calories: est.calories,
      macros: Macros(protein: est.protein, carbs: est.carbs, fat: est.fat),
      source: EstimateSource.ai,
      confidence: est.confidence == 'high' ? 'medium' : 'low',
      detail: est.note.isNotEmpty ? est.note : 'تقدير ذكاء اصطناعي',
    );
  }
}
