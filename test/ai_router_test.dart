import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zad/services/ai_router.dart';
import 'package:zad/services/ai_service.dart';

/// مزوّد وهمي يتحكّم فيه الاختبار: ينجح أو يسقط حسب الطلب.
class _FakeProvider implements AiService {
  @override
  final String name;
  @override
  final bool isConfigured;
  @override
  final Set<AiTask> capabilities;

  final bool fails;
  int textCalls = 0;
  int visionCalls = 0;
  bool closed = false;

  _FakeProvider(
    this.name, {
    this.isConfigured = true,
    this.fails = false,
    this.capabilities = const {AiTask.text, AiTask.vision},
  });

  FoodEstimate _result() => FoodEstimate(
      name: name, calories: 100, protein: 1, carbs: 2, fat: 3);

  @override
  Future<FoodEstimate> estimateFromText(String description) async {
    textCalls++;
    if (fails) throw Exception('$name down');
    return _result();
  }

  @override
  Future<FoodEstimate> estimateFromImage(Uint8List bytes,
      {String mimeType = 'image/jpeg'}) async {
    visionCalls++;
    if (fails) throw Exception('$name down');
    return _result();
  }

  @override
  void close() => closed = true;
}

void main() {
  final bytes = Uint8List.fromList([1, 2, 3]);

  test('النص: يفضّل groq وهو شغّال', () async {
    final groq = _FakeProvider('groq');
    final gemini = _FakeProvider('gemini');
    final r = AiRouter(providers: [groq, gemini]);
    expect((await r.estimateFromText('تمر')).name, 'groq');
    expect(gemini.textCalls, 0);
  });

  test('سقوط المزوّد الأول لا يُسقط الميزة — ينتقل للثاني', () async {
    final groq = _FakeProvider('groq', fails: true);
    final gemini = _FakeProvider('gemini');
    final r = AiRouter(providers: [groq, gemini]);

    expect((await r.estimateFromText('تمر')).name, 'gemini',
        reason: 'المفتاح الثاني لازم يُستعمل فعلاً لا أن يبقى حبراً على ورق');
    expect(groq.textCalls, 1);
    expect(gemini.textCalls, 1);
  });

  test('الرؤية: تفضّل gemini، وترجع لـ groq لو سقطت', () async {
    final groq = _FakeProvider('groq');
    final gemini = _FakeProvider('gemini', fails: true);
    final r = AiRouter(providers: [groq, gemini]);

    expect((await r.estimateFromImage(bytes)).name, 'groq');
    expect(gemini.visionCalls, 1);
  });

  test('سقوط الجميع يرمي آخر خطأ لا خطأ "لا يوجد مزوّد"', () async {
    final r = AiRouter(providers: [
      _FakeProvider('groq', fails: true),
      _FakeProvider('gemini', fails: true),
    ]);
    await expectLater(r.estimateFromText('تمر'), throwsA(isA<Exception>()));
  });

  test('مزوّد غير مضبوط يُتجاهل تماماً', () async {
    final groq = _FakeProvider('groq', isConfigured: false);
    final gemini = _FakeProvider('gemini');
    final r = AiRouter(providers: [groq, gemini]);

    expect((await r.estimateFromText('تمر')).name, 'gemini');
    expect(groq.textCalls, 0);
    expect(r.providerFor(AiTask.text), 'gemini');
  });

  test('بلا مزوّد مضبوط: hasText/hasVision = false والنداء يرمي', () async {
    final r = AiRouter(providers: [_FakeProvider('groq', isConfigured: false)]);
    expect(r.hasText, isFalse);
    expect(r.hasVision, isFalse);
    expect(r.providerFor(AiTask.text), isNull);
    await expectLater(r.estimateFromText('تمر'), throwsA(isA<StateError>()));
  });

  test('مزوّد نصي فقط لا يُستدعى لمهمة رؤية', () async {
    final textOnly = _FakeProvider('groq', capabilities: const {AiTask.text});
    final r = AiRouter(providers: [textOnly]);
    expect(r.hasVision, isFalse);
    await expectLater(r.estimateFromImage(bytes), throwsA(isA<StateError>()));
    expect(textOnly.visionCalls, 0);
  });

  test('close يغلق كل المزوّدات — وإلا تسرّب pool لكل فتح للشاشة', () {
    final groq = _FakeProvider('groq');
    final gemini = _FakeProvider('gemini');
    AiRouter(providers: [groq, gemini]).close();
    expect(groq.closed, isTrue);
    expect(gemini.closed, isTrue);
  });
}
