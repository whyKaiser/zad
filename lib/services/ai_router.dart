import 'package:flutter/foundation.dart';

import 'ai_service.dart';
import 'gemini_ai_service.dart';

/// يوجّه كل مهمة للمزوّد الأقوى فيها:
///   نص   → Groq أولاً (الأسرع)، وإلا Gemini.
///   صورة → Gemini أولاً (الأفضل رؤية)، وإلا أي مزوّد رؤية.
/// تحط المفتاحين (أو واحد) وهو يختار المتاح تلقائياً.
class AiRouter {
  final List<AiService> _providers;

  AiRouter({List<AiService>? providers})
      : _providers = providers ?? [GroqAiService(), GeminiAiService()];

  /// كل المزوّدات الصالحة للمهمة مرتّبة حسب الأفضلية — لا واحداً فقط،
  /// وإلا فسقوط المزوّد الأول يُسقط الميزة كلها والمفتاح الثاني لا يُستعمل أبداً.
  List<AiService> _candidates(AiTask task, List<String> priority) {
    final out = <AiService>[];
    for (final preferred in priority) {
      for (final p in _providers) {
        if (p.name == preferred &&
            p.isConfigured &&
            p.capabilities.contains(task) &&
            !out.contains(p)) {
          out.add(p);
        }
      }
    }
    for (final p in _providers) {
      if (p.isConfigured && p.capabilities.contains(task) && !out.contains(p)) {
        out.add(p);
      }
    }
    return out;
  }

  AiService? _pick(AiTask task, List<String> priority) {
    final c = _candidates(task, priority);
    return c.isEmpty ? null : c.first;
  }

  /// يجرّب المزوّدات بالترتيب ويرجع أول نجاح. لو سقطت كلها رمى آخر خطأ.
  Future<FoodEstimate> _tryEach(
    AiTask task,
    List<String> priority,
    String noProviderMessage,
    Future<FoodEstimate> Function(AiService) call,
  ) async {
    final candidates = _candidates(task, priority);
    if (candidates.isEmpty) throw StateError(noProviderMessage);
    Object lastError = StateError(noProviderMessage);
    for (final p in candidates) {
      try {
        return await call(p);
      } catch (e) {
        debugPrint('AiRouter: ${p.name} فشل — $e');
        lastError = e;
      }
    }
    throw lastError;
  }

  bool get hasText => _pick(AiTask.text, const ['groq', 'gemini']) != null;
  bool get hasVision => _pick(AiTask.vision, const ['gemini', 'groq']) != null;

  /// اسم المزوّد اللي بيُستدعى لمهمة معيّنة (للعرض/التشخيص).
  String? providerFor(AiTask task) =>
      _pick(task, task == AiTask.vision ? const ['gemini', 'groq'] : const ['groq', 'gemini'])?.name;

  Future<FoodEstimate> estimateFromText(String description) => _tryEach(
        AiTask.text,
        const ['groq', 'gemini'],
        'لا يوجد مزوّد نصي مضبوط — أضف GROQ_API_KEY أو GEMINI_API_KEY',
        (p) => p.estimateFromText(description),
      );

  Future<FoodEstimate> estimateFromImage(Uint8List bytes,
          {String mimeType = 'image/jpeg'}) =>
      _tryEach(
        AiTask.vision,
        const ['gemini', 'groq'],
        'لا يوجد مزوّد رؤية مضبوط — أضف GEMINI_API_KEY',
        (p) => p.estimateFromImage(bytes, mimeType: mimeType),
      );

  /// يغلق اتصالات كل المزوّدات — بدونه يتسرّب pool لكل فتح للشاشة.
  void close() {
    for (final p in _providers) {
      p.close();
    }
  }
}
