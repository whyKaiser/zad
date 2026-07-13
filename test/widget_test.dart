import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zad/main.dart';
import 'package:zad/data/profile_controller.dart';
import 'package:zad/l10n/app_localizations.dart';
import 'package:zad/l10n/locale_controller.dart';
import 'package:zad/models/user_profile.dart';
import 'package:zad/theme/theme_controller.dart';

const _sample = UserProfile(
  name: 'عبدالله',
  gender: Gender.male,
  age: 28,
  heightCm: 175,
  weightKg: 78,
  activity: ActivityLevel.moderate,
  goal: GoalType.lose,
);

ZadApp _app(ProfileController profile) => ZadApp(
      themeController: ThemeController(),
      localeController: LocaleController(),
      profileController: profile,
      userId: 'test-user',
    );

void main() {
  testWidgets('أول مرة: يعرض onboarding', (tester) async {
    await tester.pumpWidget(_app(ProfileController()));
    await tester.pumpAndSettle();
    expect(find.text('أهلاً بك في زاد'), findsOneWidget);
  });

  testWidgets('مع ملف جاهز: يعرض الرئيسية', (tester) async {
    await tester.pumpWidget(_app(ProfileController.seeded(_sample)));
    await tester.pumpAndSettle();
    expect(find.text('مساء الخير'), findsOneWidget);
    expect(find.text('عبدالله'), findsOneWidget); // اسم المستخدم في الشريط العلوي
  });

  test('الترجمة تتبدّل بين العربي والإنجليزي', () {
    final ar = AppLocalizations(const Locale('ar'));
    final en = AppLocalizations(const Locale('en'));
    expect(ar.greeting, 'مساء الخير');
    expect(en.greeting, 'Good evening');
    expect(ar.tabChallenges, 'التحديات');
    expect(en.tabChallenges, 'Challenges');
  });

  test('حساب الهدف: Mifflin-St Jeor + تعديل الهدف', () {
    // ذكر 78كغ 175سم 28سنة، متوسط النشاط، إنقاص
    // BMR = 10*78 + 6.25*175 - 5*28 + 5 = 780 + 1093.75 - 140 + 5 = 1738.75
    // TDEE = *1.55 = 2695 ، إنقاص -500 = ~2195
    expect(_sample.targetCalories, inInclusiveRange(2150, 2240));
    expect(_sample.targetMacros.protein, 140); // 1.8*78
  });
}
