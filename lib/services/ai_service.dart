import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'ai_prompts.dart';

/// المهام اللي يقدر مزوّد AI يخدمها.
enum AiTask { text, vision }

/// نتيجة تقدير صنف غذائي.
class FoodEstimate {
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final String confidence;
  final String note;

  FoodEstimate({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.confidence = 'medium',
    this.note = '',
  });

  factory FoodEstimate.fromJson(Map<String, dynamic> j) => FoodEstimate(
        name: (j['name'] ?? '') as String,
        calories: (j['calories'] as num? ?? 0).round(),
        protein: (j['protein_g'] as num? ?? 0).round(),
        carbs: (j['carbs_g'] as num? ?? 0).round(),
        fat: (j['fat_g'] as num? ?? 0).round(),
        confidence: (j['confidence'] ?? 'medium') as String,
        note: (j['note'] ?? '') as String,
      );
}

/// مهل موحّدة: بدونها يعلّق المؤشّر للأبد على شبكة ميتة.
class AiTimeouts {
  static const text = Duration(seconds: 20);
  static const vision = Duration(seconds: 45);
}

/// واجهة موحّدة لأي مزوّد AI. الـ router يختار بينها حسب المهمة.
abstract class AiService {
  String get name;
  bool get isConfigured;
  Set<AiTask> get capabilities;

  Future<FoodEstimate> estimateFromText(String description);
  Future<FoodEstimate> estimateFromImage(Uint8List bytes, {String mimeType});

  /// يحرّر اتصالات HTTP المفتوحة. يُستدعى من dispose الشاشة.
  void close();
}

/// Groq (مجاني/سريع — Llama). نص فقط. API متوافق مع OpenAI.
///   flutter run --dart-define=GROQ_API_KEY=gsk_xxxx
class GroqAiService implements AiService {
  static const _apiKey = String.fromEnvironment('GROQ_API_KEY');
  static const _model = 'llama-3.3-70b-versatile';
  /// موديل الرؤية — يقرأ صور الأكل بنفس مفتاح Groq.
  static const _visionModel = 'meta-llama/llama-4-scout-17b-16e-instruct';
  static final _endpoint =
      Uri.parse('https://api.groq.com/openai/v1/chat/completions');

  final http.Client _client;
  GroqAiService([http.Client? client]) : _client = client ?? http.Client();

  @override
  String get name => 'groq';

  @override
  bool get isConfigured => _apiKey.isNotEmpty;

  @override
  Set<AiTask> get capabilities => {AiTask.text, AiTask.vision};

  @override
  Future<FoodEstimate> estimateFromText(String description) async {
    if (!isConfigured) {
      throw StateError('GROQ_API_KEY غير مضبوط — مرّره عبر --dart-define');
    }
    final res = await _client.post(
      _endpoint,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': _model,
        'temperature': 0.3,
        'response_format': {'type': 'json_object'},
        'messages': [
          {'role': 'system', 'content': AiPrompts.system},
          {'role': 'user', 'content': AiPrompts.estimateFromText(description)},
        ],
      }),
    ).timeout(AiTimeouts.text);
    return _parse(res);
  }

  /// استخراج دفاعي: ردّ محجوب أو `choices` فاضية كانت ترمي TypeError غامضاً
  /// بدل رسالة تُفهم.
  FoodEstimate _parse(http.Response res) {
    if (res.statusCode != 200) {
      throw Exception('فشل نداء Groq: ${res.statusCode} ${res.body}');
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final choices = body['choices'];
    String? content;
    if (choices is List && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map) {
        final message = first['message'];
        if (message is Map) content = message['content'] as String?;
      }
    }
    if (content == null || content.trim().isEmpty) {
      throw Exception('ردّ Groq فارغ أو محجوب');
    }
    final decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('ردّ Groq ليس JSON متوقّعاً');
    }
    return FoodEstimate.fromJson(decoded);
  }

  @override
  void close() => _client.close();

  @override
  Future<FoodEstimate> estimateFromImage(Uint8List bytes, {String mimeType = 'image/jpeg'}) async {
    if (!isConfigured) {
      throw StateError('GROQ_API_KEY غير مضبوط — مرّره عبر --dart-define');
    }
    final dataUri = 'data:$mimeType;base64,${base64Encode(bytes)}';
    final res = await _client.post(
      _endpoint,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': _visionModel,
        'temperature': 0.3,
        'response_format': {'type': 'json_object'},
        'messages': [
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': '${AiPrompts.system}\n\n${AiPrompts.estimateFromImage()}'},
              {
                'type': 'image_url',
                'image_url': {'url': dataUri},
              },
            ],
          },
        ],
      }),
    ).timeout(AiTimeouts.vision);
    return _parse(res);
  }
}
