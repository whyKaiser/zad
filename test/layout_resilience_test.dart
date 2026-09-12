import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zad/features/activity/activity_screen.dart';
import 'package:zad/features/analytics/analytics_screen.dart';
import 'package:zad/features/challenges/challenges_screen.dart';
import 'package:zad/features/challenges/daily_tasks_screen.dart';
import 'package:zad/features/fasting/fasting_screen.dart';
import 'package:zad/features/home/home_screen.dart';
import 'package:zad/features/meal_plan/meal_plan_screen.dart';
import 'package:zad/features/profile/export_data_screen.dart';
import 'package:zad/features/profile/profile_screen.dart';
import 'package:zad/features/recipes/recipes_screen.dart';
import 'package:zad/features/restaurants/restaurants_screen.dart';
import 'package:zad/features/weight/weight_screen.dart';

import 'helpers/pump_app.dart';

/// المستخدم يكبّر خط النظام، أو يفتح التطبيق على جهاز ضيّق.
/// أبل تعتبر احترام حجم الخط شرطاً لا خياراً — والتخطيط يجب أن يتمدّد معه
/// لا أن ينكسر. أي طفح (`RenderFlex overflowed`) يسقط هذا الاختبار.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final screens = <String, Widget Function()>{
    'الرئيسية': () => const HomeScreen(),
    'التحليلات': () => const AnalyticsScreen(),
    'التحديات': () => const ChallengesScreen(),
    'مهام اليوم': () => const DailyTasksScreen(),
    'النشاط': () => const ActivityScreen(),
    'الصيام': () => const FastingScreen(),
    'الوصفات': () => const RecipesScreen(),
    'الوزن': () => const WeightScreen(),
    'خطة الوجبات': () => const MealPlanScreen(),
    'المطاعم': () => const RestaurantsScreen(),
    'الملف الشخصي': () => const ProfileScreen(),
    'تصدير البيانات': () => const ExportDataScreen(),
  };

  /// الطفح يُبلَّغ كخطأ في شجرة الودجت لا كاستثناء يُرمى، فنلتقطه صراحةً.
  Future<void> expectNoOverflow(
    WidgetTester tester,
    Widget screen, {
    required double textScale,
    required Size size,
    Locale locale = const Locale('ar'),
  }) async {
    await pumpScreen(tester, screen,
        textScale: textScale, size: size, locale: locale);
    await tester.pumpAndSettle(const Duration(milliseconds: 50));

    final err = tester.takeException();
    await tester.pumpWidget(const SizedBox());
    await tester.pump();

    expect(err, isNull,
        reason: 'حجم خط x$textScale على ${size.width.toInt()}px — $err');
  }

  group('تكبير خط النظام لا يكسر التخطيط', () {
    for (final scale in [1.3, 1.6]) {
      screens.forEach((name, build) {
        testWidgets('$name عند ×$scale', (tester) async {
          await expectNoOverflow(tester, build(),
              textScale: scale, size: const Size(420, 1400));
        });
      });
    }
  });

  group('شاشة ضيّقة (iPhone SE) لا تطفح', () {
    screens.forEach((name, build) {
      testWidgets(name, (tester) async {
        await expectNoOverflow(tester, build(),
            textScale: 1.0, size: const Size(320, 1200));
      });
    });
  });

  group('الإنجليزية أطول من العربية في الغالب — تُختبر منفصلة', () {
    screens.forEach((name, build) {
      testWidgets(name, (tester) async {
        await expectNoOverflow(tester, build(),
            textScale: 1.3,
            size: const Size(360, 1400),
            locale: const Locale('en'));
      });
    });
  });
}
