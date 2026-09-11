import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'ai_prompts.dart';
import 'ai_service.dart';

/// Gemini Flash (مجاني). يدعم النص + الرؤية (تحليل صورة الأكل).
///   flutter run --dart-define=GEMINI_API_KEY=AIza_xxxx
class GeminiAiService implements AiService {
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _model = 'gemini-flash-latest';

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

  Future<FoodEstimate> _send(List<Map<String, dynamic>> parts,
      {required Duration timeout}) async {
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
    ).timeout(timeout);
    if (res.statusCode != 200) {
      throw Exception('فشل نداء Gemini: ${res.statusCode} ${res.body}');
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    // ردّ محجوب بفلتر الأمان يرجع `candidates` فاضية — لا نفهرس أعمى.
    final cands = body['candidates'];
    String? text;
    if (cands is List && cands.isNotEmpty) {
      final first = cands.first;
      if (first is Map) {
        final content = first['content'];
        if (content is Map) {
          final parts = content['parts'];
          if (parts is List && parts.isNotEmpty) {
            final part = parts.first;
            if (part is Map) text = part['text'] as String?;
          }
        }
      }
    }
    if (text == null || text.trim().isEmpty) {
      throw Exception('ردّ Gemini فارغ أو محجوب');
    }
    final decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('ردّ Gemini ليس JSON متوقّعاً');
    }
    return FoodEstimate.fromJson(decoded);
  }

  @override
  void close() => _client.close();

  @override
  Future<FoodEstimate> estimateFromText(String description) =>
      _send([
        {'text': AiPrompts.system},
        {'text': AiPrompts.estimateFromText(description)},
      ], timeout: AiTimeouts.text);

  @override
  Future<FoodEstimate> estimateFromImage(Uint8List bytes, {String mimeType = 'image/jpeg'}) =>
      _send([
        {'text': AiPrompts.system},
        {'text': AiPrompts.estimateFromImage()},
        {
          'inline_data': {'mime_type': mimeType, 'data': base64Encode(bytes)}
        },
      ], timeout: AiTimeouts.vision);
}
