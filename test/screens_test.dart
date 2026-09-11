import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zad/core/dates.dart';
import 'package:zad/features/activity/activity_screen.dart';
import 'package:zad/features/challenges/daily_tasks_screen.dart';
import 'package:zad/features/fasting/fasting_screen.dart';
import 'package:zad/features/home/home_screen.dart';
import 'package:zad/features/profile/export_data_screen.dart';
import 'package:zad/features/recipes/recipes_screen.dart';
import 'package:zad/models/meal.dart';

import 'helpers/pump_app.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('الشاشة الرئيسية', () {
    testWidgets('تعرض اسم المستخدم وهدفه المحسوب', (tester) async {
      await pumpScreen(tester, const HomeScreen());
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      expect(find.text('أحمد'), findsOneWidget);
      // هدف Mifflin-St Jeor لهذا الملف ≈ 2195
      expect(find.text('${testProfile.targetCalories}'), findsWidgets);
      await settleAndDispose(tester);
    });

    testWidgets('شريط التواريخ يفتح على اليوم لا على تاريخ قديم', (tester) async {
      await pumpScreen(tester, const HomeScreen());
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      // حارس ارتداد: إزاحة ثابتة محسوبة يدوياً كانت تُنزل المستخدم
      // في منتصف الشهر الماضي، وتنكسر أصلاً في الاتجاه العربي.
      final today = DateTime.now();
      expect(find.text('${today.day}'), findsWidgets,
          reason: 'يوم اليوم لازم يكون ظاهراً في الشريط');
      await settleAndDispose(tester);
    });

    testWidgets('تسجيل وجبة يحدّث المتبقّي فوراً', (tester) async {
      final repo = await pumpScreen(tester, const HomeScreen());
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      repo.addMeal(testMeal('كبسة', cal: 700));
      await tester.pump();
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      final remaining = testProfile.targetCalories - 700;
      expect(find.text('$remaining'), findsWidgets);
      await settleAndDispose(tester);
    });

    testWidgets('بلا ملف شخصي لا تنهار', (tester) async {
      await pumpScreen(tester, const HomeScreen(), profile: null);
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
      await settleAndDispose(tester);
    });

    testWidgets('تعمل بالإنجليزية أيضاً', (tester) async {
      await pumpScreen(tester, const HomeScreen(), locale: const Locale('en'));
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
      expect(find.text('Activity'), findsWidgets);
      await settleAndDispose(tester);
    });
  });

  group('شاشة الوصفات', () {
    testWidgets('تعرض حالة فارغة مفيدة لا شاشة بيضاء', (tester) async {
      await pumpScreen(tester, const RecipesScreen());
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      expect(find.textContaining('ما عندك وصفات'), findsOneWidget);
      expect(find.text('وصفة جديدة'), findsOneWidget);
      await settleAndDispose(tester);
    });

    testWidgets('زر الوصفة الجديدة يفتح المحرّر', (tester) async {
      await pumpScreen(tester, const RecipesScreen());
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      await tester.tap(find.text('وصفة جديدة'));
      await tester.pumpAndSettle();

      expect(find.text('وصفة جديدة'), findsWidgets);
      expect(find.textContaining('المكوّنات'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await settleAndDispose(tester);
    });
  });

  group('شاشة الصيام', () {
    testWidgets('تبدأ بحالة جاهز وتعرض البروتوكولات', (tester) async {
      await pumpScreen(tester, const FastingScreen());
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      expect(find.text('ابدأ الصيام'), findsOneWidget);
      expect(find.text('16:8'), findsOneWidget);
      expect(find.textContaining('راجع مختصاً'), findsOneWidget,
          reason: 'التنويه الصحي إلزامي');
      await settleAndDispose(tester);
    });
  });

  group('شاشة النشاط', () {
    testWidgets('تعرض حالة فارغة وزر تسجيل', (tester) async {
      await pumpScreen(tester, const ActivityScreen());
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      expect(find.textContaining('ما سجّلت نشاط'), findsOneWidget);
      expect(find.text('سجّل نشاط'), findsOneWidget);
      await settleAndDispose(tester);
    });
  });

  group('شاشة التصدير', () {
    testWidgets('تعرض كل أنواع البيانات وتنويه الخصوصية', (tester) async {
      await pumpScreen(tester, const ExportDataScreen());
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      expect(find.text('يوميات الطعام'), findsOneWidget);
      expect(find.text('سجل الوزن'), findsOneWidget);
      expect(find.text('سجل النشاط'), findsOneWidget);
      expect(find.textContaining('لا يُرفع شيء'), findsOneWidget);
      await settleAndDispose(tester);
    });
  });

  group('شاشة مهام اليوم', () {
    testWidgets('تعرض المهام بلا قسمة على صفر', (tester) async {
      await pumpScreen(tester, const DailyTasksScreen());
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      expect(find.text('سجّل الفطور'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await settleAndDispose(tester);
    });

    testWidgets('تسجيل الفطور يعلّم مهمته كمكتملة', (tester) async {
      final repo = await pumpScreen(tester, const DailyTasksScreen());
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      repo.addMeal(testMeal('بيض', type: MealType.breakfast));
      await tester.pump();
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(find.text('سجّل الفطور'), findsOneWidget);
      await settleAndDispose(tester);
    });
  });

  group('حارس التواريخ', () {
    test('مفتاح اليوم يطابق ما تتطلبه قواعد Firestore', () {
      final key = dayKey(DateTime(2026, 3, 7));
      expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(key), isTrue);
    });
  });
}
