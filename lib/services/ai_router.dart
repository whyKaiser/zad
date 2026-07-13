import 'dart:typed_data';

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

  AiService? _pick(AiTask task, List<String> priority) {
    for (final preferred in priority) {
      for (final p in _providers) {
        if (p.name == preferred && p.isConfigured && p.capabilities.contains(task)) {
          return p;
        }
      }
    }
    // احتياطي: أي مزوّد مضبوط يدعم المهمة.
    for (final p in _providers) {
      if (p.isConfigured && p.capabilities.contains(task)) return p;
    }
    return null;
  }

  bool get hasText => _pick(AiTask.text, const ['groq', 'gemini']) != null;
  bool get hasVision => _pick(AiTask.vision, const ['gemini', 'groq']) != null;

  /// اسم المزوّد اللي بيُستدعى لمهمة معيّنة (للعرض/التشخيص).
  String? providerFor(AiTask task) =>
      _pick(task, task == AiTask.vision ? const ['gemini', 'groq'] : const ['groq', 'gemini'])?.name;

  Future<FoodEstimate> estimateFromText(String description) {
    final p = _pick(AiTask.text, const ['groq', 'gemini']);
    if (p == null) throw StateError('لا يوجد مزوّد نصي مضبوط — أضف GROQ_API_KEY أو GEMINI_API_KEY');
    return p.estimateFromText(description);
  }

  Future<FoodEstimate> estimateFromImage(Uint8List bytes, {String mimeType = 'image/jpeg'}) {
    final p = _pick(AiTask.vision, const ['gemini', 'groq']);
    if (p == null) throw StateError('لا يوجد مزوّد رؤية مضبوط — أضف GEMINI_API_KEY');
    return p.estimateFromImage(bytes, mimeType: mimeType);
  }
}
