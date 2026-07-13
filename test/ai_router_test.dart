import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zad/services/ai_router.dart';
import 'package:zad/services/ai_service.dart';

/// مزوّد وهمي للتحكّم بالاختبار.
class _Fake implements AiService {
  @override
  final String name;
  @override
  final bool isConfigured;
  @override
  final Set<AiTask> capabilities;

  _Fake(this.name, {required this.isConfigured, required this.capabilities});

  @override
  Future<FoodEstimate> estimateFromText(String d) async =>
      FoodEstimate(name: name, calories: 0, protein: 0, carbs: 0, fat: 0);

  @override
  Future<FoodEstimate> estimateFromImage(Uint8List b, {String mimeType = 'image/jpeg'}) async =>
      FoodEstimate(name: name, calories: 0, protein: 0, carbs: 0, fat: 0);
}

void main() {
  test('النص يروح لـ Groq لما الاثنان مضبوطان', () {
    final r = AiRouter(providers: [
      _Fake('groq', isConfigured: true, capabilities: {AiTask.text}),
      _Fake('gemini', isConfigured: true, capabilities: {AiTask.text, AiTask.vision}),
    ]);
    expect(r.providerFor(AiTask.text), 'groq');
    expect(r.providerFor(AiTask.vision), 'gemini');
  });

  test('النص يسقط على Gemini لو Groq غير مضبوط', () {
    final r = AiRouter(providers: [
      _Fake('groq', isConfigured: false, capabilities: {AiTask.text}),
      _Fake('gemini', isConfigured: true, capabilities: {AiTask.text, AiTask.vision}),
    ]);
    expect(r.providerFor(AiTask.text), 'gemini');
    expect(r.hasVision, true);
  });

  test('بلا مفاتيح: لا مزوّد، والاستدعاء يرمي خطأ واضح', () {
    final r = AiRouter(providers: [
      _Fake('groq', isConfigured: false, capabilities: {AiTask.text}),
      _Fake('gemini', isConfigured: false, capabilities: {AiTask.text, AiTask.vision}),
    ]);
    expect(r.hasText, false);
    expect(r.hasVision, false);
    expect(() => r.estimateFromText('كبسة'), throwsStateError);
  });
}
