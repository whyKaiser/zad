import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// ملخّص أسبوع المستخدم — أرقام محسوبة محلياً تُمرَّر للنموذج.
/// لا نرسل أي معرّف شخصي، فقط أرقام مجهولة.
@immutable
class WeekSummary {
  final int daysLogged;
  final int avgCalories;
  final int goalCalories;
  final int avgProtein;
  final int goalProtein;
  final int daysOnTarget;
  final int streak;
  final int waterAvgCups;
  final int workouts;
  final double? weightChangeKg;
  final String goalLabel; // إنقاص / محافظة / زيادة

  const WeekSummary({
    required this.daysLogged,
    required this.avgCalories,
    required this.goalCalories,
    required this.avgProtein,
    required this.goalProtein,
    required this.daysOnTarget,
    required this.streak,
    required this.waterAvgCups,
    required this.workouts,
    required this.goalLabel,
    this.weightChangeKg,
  });

  /// هل عند المستخدم بيانات كافية لتقرير ذي معنى؟
  bool get hasEnoughData => daysLogged >= 2;

  Map<String, dynamic> toPromptJson() => {
        'أيام_مسجّلة': daysLogged,
        'متوسط_السعرات': avgCalories,
        'هدف_السعرات': goalCalories,
        'متوسط_البروتين_غ': avgProtein,
        'هدف_البروتين_غ': goalProtein,
        'أيام_ضمن_الهدف': daysOnTarget,
        'الستريك': streak,
        'متوسط_أكواب_الماء': waterAvgCups,
        'تمارين_الأسبوع': workouts,
        if (weightChangeKg != null)
          'تغيّر_الوزن_كغ': double.parse(weightChangeKg!.toStringAsFixed(1)),
        'هدف_المستخدم': goalLabel,
      };
}

/// نتيجة التقرير: ملخّص + نصيحة واحدة قابلة للتنفيذ.
@immutable
class CoachReport {
  final String headline;
  final String body;
  final String tip;

  const CoachReport({required this.headline, required this.body, required this.tip});

  factory CoachReport.fromJson(Map<String, dynamic> j) => CoachReport(
        headline: (j['headline'] ?? '') as String,
        body: (j['body'] ?? '') as String,
        tip: (j['tip'] ?? '') as String,
      );
}

/// مدرّب أسبوعي يلخّص الأداء بالعربي ويعطي خطوة واحدة واضحة.
/// يعتمد نفس مفتاح Groq، ويسقط لتقرير محلي إن لم يتوفّر.
class WeeklyCoachService {
  static const _apiKey = String.fromEnvironment('GROQ_API_KEY');
  static const _model = 'llama-3.3-70b-versatile';
  static final _endpoint =
      Uri.parse('https://api.groq.com/openai/v1/chat/completions');

  final http.Client _client;
  WeeklyCoachService([http.Client? client]) : _client = client ?? http.Client();

  bool get isConfigured => _apiKey.isNotEmpty;

  static const _system = '''
أنت مدرّب تغذية عربي داخل تطبيق "زاد". تخاطب المستخدم بلهجة سعودية بيضاء مفهومة.
- لخّص أسبوعه بصدق: اذكر ما أحسن فيه أولاً ثم ما يحتاج تحسينه.
- أعطِ **نصيحة واحدة فقط** قابلة للتنفيذ هذا الأسبوع. لا قائمة نصائح.
- لا تشخيص ولا نصيحة طبية. لا تقترح سعرات أقل من 1200.
- إن كانت البيانات قليلة، شجّعه على الاستمرار بلا لوم.
- لا تذكر أنك ذكاء اصطناعي ولا تشرح طريقتك.
''';

  String _userPrompt(Map<String, dynamic> stats) => '''
هذي أرقام أسبوع المستخدم (مجهولة، بلا أي بيانات شخصية):
${jsonEncode(stats)}

أرجِع JSON فقط بهذا الشكل:
{"headline":"عنوان قصير جداً (٤ كلمات كحد أقصى)","body":"فقرة من ٢-٣ أسطر تلخّص الأسبوع","tip":"نصيحة واحدة عملية لهذا الأسبوع"}
''';

  Future<CoachReport> generate(WeekSummary week) async {
    if (!isConfigured) return _fallback(week);
    try {
      final res = await _client
          .post(
            _endpoint,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': _model,
              'temperature': 0.6,
              'response_format': {'type': 'json_object'},
              'messages': [
                {'role': 'system', 'content': _system},
                {'role': 'user', 'content': _userPrompt(week.toPromptJson())},
              ],
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return _fallback(week);
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final content = body['choices']?[0]?['message']?['content'] as String?;
      if (content == null || content.isEmpty) return _fallback(week);
      final report =
          CoachReport.fromJson(jsonDecode(content) as Map<String, dynamic>);
      if (report.body.isEmpty) return _fallback(week);
      return report;
    } catch (e) {
      debugPrint('WeeklyCoach error: $e');
      return _fallback(week);
    }
  }

  /// تقرير محلي بلا إنترنت — يبقى مفيداً ولا يعرض رسالة خطأ خام.
  CoachReport _fallback(WeekSummary w) {
    if (!w.hasEnoughData) {
      return const CoachReport(
        headline: 'بداية الطريق',
        body: 'سجّلت أياماً قليلة هذا الأسبوع. التتبّع المستمر هو أهم عامل '
            'في الوصول لهدفك — حتى لو كان التسجيل تقريبياً.',
        tip: 'سجّل وجباتك ٣ أيام متتالية هذا الأسبوع، وخلها عادة.',
      );
    }
    final diff = w.avgCalories - w.goalCalories;
    final over = diff > 150;
    final under = diff < -250;
    final proteinLow = w.goalProtein > 0 && w.avgProtein < w.goalProtein * 0.8;

    final headline = over
        ? 'فوق هدفك قليلاً'
        : under
            ? 'تحت هدفك كثير'
            : 'أسبوع متّزن';

    final body = StringBuffer()
      ..write('سجّلت ${w.daysLogged} أيام، بمتوسط ${w.avgCalories} سعرة '
          'مقابل هدف ${w.goalCalories}. ')
      ..write(w.daysOnTarget > 0
          ? 'التزمت بهدفك في ${w.daysOnTarget} منها. '
          : 'ما وصلت لهدفك في أي يوم. ')
      ..write(w.workouts > 0 ? 'وسجّلت ${w.workouts} تمرين.' : '');

    final tip = proteinLow
        ? 'ارفع البروتين: أضف مصدر بروتين لكل وجبة (بيض، دجاج، لبن) '
            'للوصول لـ ${w.goalProtein} جرام.'
        : over
            ? 'قلّل ١٥٠ سعرة يومياً — غالباً تجيك من المشروبات والإضافات.'
            : under
                ? 'الأكل القليل جداً يبطّئ تقدّمك. قرّب من هدفك ${w.goalCalories} سعرة.'
                : 'استمر على نفس النمط، وزد كوب ماء يومياً.';

    return CoachReport(headline: headline, body: body.toString(), tip: tip);
  }

  void close() => _client.close();
}
