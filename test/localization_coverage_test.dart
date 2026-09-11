import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// نص عربي مكتوب مباشرة في شاشة = مستخدم الإنجليزية يشوف عربي.
/// وقع فعلاً في شاشات الباركود والصورة والمطاعم والصيام والوزن ودهون الجسم
/// قبل أن يُمسك يدوياً، فهذا الاختبار يمنع رجوعه بصمت.
void main() {
  final arabic = RegExp(r'[\u0600-\u06FF]');

  /// حقول بيانات ثنائية اللغة: `nameAr` يقابله `nameEn`، والاختيار بينهما
  /// يتم عند العرض. عربيّها مقصود.
  final bilingualField = RegExp(r'\w*Ar\s*:');

  /// استثناءات مقصودة — كل واحد معه سببه.
  const allowed = <String, String>{
    'lib/features/analytics/weekly_report_screen.dart':
        'تسميات الهدف تُرسل داخل برومبت عربي للمدرّب، لا تُعرض للمستخدم',
    'lib/features/meal_plan/meal_plan_screen.dart':
        'قائمة _days العربية يقابلها _daysEn ويُختار بينهما عند العرض',
    'lib/features/weight/weight_screen.dart':
        'حقول القياسات صفوف (مفتاح، رمز، عربي، إنجليزي) يُختار منها عند العرض',
    'lib/features/profile/profile_screen.dart': 'اسم العلامة «زاد» لا يُترجم',
  };

  /// يشيل تعليقاً في آخر السطر حتى لا يُحسب كنص معروض.
  String stripTrailingComment(String line) {
    var inString = false;
    String? quote;
    for (var i = 0; i < line.length - 1; i++) {
      final ch = line[i];
      if (inString) {
        if (ch == r'\') {
          i++;
        } else if (ch == quote) {
          inString = false;
        }
      } else if (ch == "'" || ch == '"') {
        inString = true;
        quote = ch;
      } else if (ch == '/' && line[i + 1] == '/') {
        return line.substring(0, i);
      }
    }
    return line;
  }

  test('لا نص عربي معروض خارج طبقة الترجمة في lib/features', () {
    final offenders = <String>[];
    final dir = Directory('lib/features');
    expect(dir.existsSync(), isTrue, reason: 'شغّل الاختبار من جذر المشروع');

    for (final f in dir.listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final rel = f.path.replaceAll(r'\', '/');
      if (allowed.containsKey(rel)) continue;

      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final code = stripTrailingComment(lines[i]);
        if (!arabic.hasMatch(code)) continue;
        if (code.trimLeft().startsWith('//')) continue;
        if (bilingualField.hasMatch(code)) continue;

        // الترجمة قد تكون على نفس السطر أو على رأس تعبير شرطي متعدّد الأسطر.
        final window =
            lines.sublist((i - 3).clamp(0, lines.length), i + 1).join('\n');
        if (window.contains('loc.') ||
            window.contains('isAr') ||
            window.contains('AppLocalizations')) {
          continue;
        }
        offenders.add('$rel:${i + 1}: ${code.trim()}');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'نص عربي بلا ترجمة — مرّره عبر AppLocalizations:\n'
          '${offenders.join('\n')}',
    );
  });

  test('كل استثناء في القائمة البيضاء ملف موجود فعلاً', () {
    for (final path in allowed.keys) {
      expect(File(path).existsSync(), isTrue,
          reason: 'استثناء ميّت في القائمة البيضاء: $path');
    }
  });
}
