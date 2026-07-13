import 'package:flutter_test/flutter_test.dart';
import 'package:zad/services/food_lookup.dart';

/// اختبار حيّ — يحتاج مفتاح:
///   flutter test test/ai_live_test.dart --dart-define=GROQ_API_KEY=gsk_xxx
/// يُتخطّى تلقائياً لو ما فيه مفتاح (عشان لا يكسر `flutter test` العادي).
const _key = String.fromEnvironment('GROQ_API_KEY');

void main() {
  test('AI يقدّر صنف غير موجود بالقاعدة (نداء حقيقي)', () async {
    final r = await FoodLookup().estimate('بيتزا مارغريتا قطعة كبيرة');
    // ignore: avoid_print
    print('نتيجة AI → ${r.name} | ${r.calories} سعرة | '
        'ب${r.macros.protein} ك${r.macros.carbs} د${r.macros.fat} | '
        'مصدر=${r.source.name} ثقة=${r.confidence}');
    expect(r.source, EstimateSource.ai);
    expect(r.calories, greaterThan(0));
    expect(r.macros.protein, greaterThan(0));
  }, timeout: const Timeout(Duration(seconds: 60)), skip: _key.isEmpty ? 'لا مفتاح GROQ_API_KEY' : false);
}
