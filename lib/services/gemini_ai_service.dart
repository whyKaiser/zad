import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'ai_prompts.dart';
import 'ai_service.dart';

/// Gemini Flash (مجاني). يدعم النص + الرؤية (تحليل صورة الأكل).
///   flutter run --dart-define=GEMINI_API_KEY=AIza_xxxx
class GeminiAiService implements AiService {
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _model = 'gemini-2.0-flash';

  final http.Client _client;
  GeminiAiService([http.Client? client]) : _client = client ?? http.Client();

  @override
  String get name => 'gemini';

  @override
  bool get isConfigured => _apiKey.isNotEmpty;

  @override
  Set<AiTask> get capabilities => {AiTask.text, AiTask.vision};

  Uri get _endpoint => Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey',
      );

  Future<FoodEstimate> _send(List<Map<String, dynamic>> parts) async {
    if (!isConfigured) {
      throw StateError('GEMINI_API_KEY غير مضبوط — مرّره عبر --dart-define');
    }
    final res = await _client.post(
      _endpoint,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {'parts': parts}
        ],
        'generationConfig': {'responseMimeType': 'application/json', 'temperature': 0.3},
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('فشل نداء Gemini: ${res.statusCode} ${res.body}');
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final text = body['candidates'][0]['content']['parts'][0]['text'] as String;
    return FoodEstimate.fromJson(jsonDecode(text) as Map<String, dynamic>);
  }

  @override
  Future<FoodEstimate> estimateFromText(String description) =>
      _send([
        {'text': AiPrompts.system},
        {'text': AiPrompts.estimateFromText(description)},
      ]);

  @override
  Future<FoodEstimate> estimateFromImage(Uint8List bytes, {String mimeType = 'image/jpeg'}) =>
      _send([
        {'text': AiPrompts.system},
        {'text': AiPrompts.estimateFromImage()},
        {
          'inline_data': {'mime_type': mimeType, 'data': base64Encode(bytes)}
        },
      ]);
}
