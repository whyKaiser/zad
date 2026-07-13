import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class FormAnalyzerScreen extends StatefulWidget {
  const FormAnalyzerScreen({super.key});

  @override
  State<FormAnalyzerScreen> createState() => _FormAnalyzerScreenState();
}

class _FormAnalyzerScreenState extends State<FormAnalyzerScreen> {
  static const _apiKey = String.fromEnvironment('GROQ_API_KEY');
  static const _model = 'llama-3.3-70b-versatile';
  static final _endpoint = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

  final _ctrl = TextEditingController();
  String _response = '';
  bool _loading = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _analyze() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    setState(() { _loading = true; _response = ''; });
    if (_apiKey.isEmpty) {
      setState(() { _response = 'مفتاح Groq غير مضبوط.'; _loading = false; });
      return;
    }
    try {
      final res = await http.post(_endpoint,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_apiKey'},
        body: jsonEncode({
          'model': _model,
          'temperature': 0.5,
          'messages': [
            {'role': 'system', 'content': 'أنت متخصص في تحليل أداء التمارين الرياضية وتقنيات الحركة.'},
            {'role': 'user', 'content': '''المستخدم يصف تمرينه: "$q"\nحلّل الوصف وقدّم:\n1. نقاط الأداء الصحيح\n2. أخطاء محتملة\n3. نصائح تحسين محددة\nأجب باختصار ووضوح بالعربية.'''},
          ],
        }),
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final content = body['choices']?[0]?['message']?['content'] as String? ?? '';
        if (mounted) setState(() { _response = content; _loading = false; });
      } else {
        if (mounted) setState(() { _response = 'خطأ ${res.statusCode}'; _loading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _response = 'تعذّر التحليل، حاول مجدداً.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(children: [
                IconButton(onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary)),
                Text(loc.isAr ? 'محلّل الأداء' : 'Form Analyzer',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: c.textPrimary)),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: c.surfaceVariant, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Icon(Icons.tips_and_updates_outlined, size: 16, color: c.accent),
                        const SizedBox(width: 8),
                        Text(loc.isAr ? 'كيف تستخدمه' : 'How to use',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.accent)),
                      ]),
                      const SizedBox(height: 8),
                      Text(
                        loc.isAr
                            ? 'صف كيف تؤدي التمرين: الوضعية، الإحساس، المشكلة. مثال: "في السكوات أشعر بألم في الركبة عند النزول"'
                            : 'Describe how you perform the exercise: position, feeling, issue. E.g. "During squats I feel knee pain on the way down"',
                        style: TextStyle(fontSize: 13, color: c.textSecondary),
                      ),
                    ]),
                  ).animate().fadeIn(duration: 350.ms),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _ctrl,
                    maxLines: 5,
                    style: TextStyle(color: c.textPrimary),
                    decoration: InputDecoration(
                      hintText: loc.isAr ? 'صف أداء تمرينك…' : 'Describe your exercise form…',
                      hintStyle: TextStyle(color: c.textTertiary),
                      filled: true, fillColor: c.surface,
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.accent)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _loading ? null : _analyze,
                      style: TextButton.styleFrom(
                        backgroundColor: c.accent, foregroundColor: c.onAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        disabledBackgroundColor: c.accent.withOpacity(0.4),
                      ),
                      child: _loading
                          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: c.onAccent))
                          : Text(loc.isAr ? 'حلّل الأداء' : 'Analyze Form',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  if (_response.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: c.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.accent.withOpacity(0.4)),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Icon(Icons.psychology_outlined, size: 18, color: c.accent),
                          const SizedBox(width: 8),
                          Text(loc.isAr ? 'تحليل الأداء' : 'Analysis',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.accent)),
                        ]),
                        const SizedBox(height: 12),
                        Text(_response, style: TextStyle(fontSize: 14, color: c.textPrimary, height: 1.6)),
                      ]),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
