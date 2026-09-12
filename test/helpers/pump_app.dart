import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:zad/data/activity_controller.dart';
import 'package:zad/data/daily_tasks_controller.dart';
import 'package:zad/data/diary_repository.dart';
import 'package:zad/data/fasting_controller.dart';
import 'package:zad/data/local_diary_repository.dart';
import 'package:zad/data/meal_plan_controller.dart';
import 'package:zad/data/measurements_controller.dart';
import 'package:zad/data/points_controller.dart';
import 'package:zad/data/profile_controller.dart';
import 'package:zad/data/recent_foods_controller.dart';
import 'package:zad/data/recipe_controller.dart';
import 'package:zad/data/unit_controller.dart';
import 'package:zad/data/water_controller.dart';
import 'package:zad/data/weight_controller.dart';
import 'package:zad/l10n/app_localizations.dart';
import 'package:zad/models/meal.dart';
import 'package:zad/models/user_profile.dart';
import 'package:zad/theme/app_palette.dart';
import 'package:zad/theme/app_theme.dart';

const testProfile = UserProfile(
  name: 'أحمد',
  gender: Gender.male,
  age: 28,
  heightCm: 175,
  weightKg: 78,
  activity: ActivityLevel.moderate,
  goal: GoalType.lose,
);

/// يركّب شاشة داخل نفس بيئة التطبيق (مزوّدات + ترجمة + ثيم + اتجاه)
/// حتى تختبر الشاشات كما تُعرض فعلاً لا كودجت معزول.
Future<LocalDiaryRepository> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  UserProfile? profile = testProfile,
  Locale locale = const Locale('ar'),
  Size size = const Size(420, 1000),
  LocalDiaryRepository? repo,
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final p = profile;
  final diary = repo ??
      LocalDiaryRepository(
        goal: DailyGoal(
          calories: p?.targetCalories ?? 2000,
          macros: p?.targetMacros ?? const Macros(protein: 150, carbs: 200, fat: 60),
        ),
        name: p?.name ?? '',
      );

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ProfileController>.value(
          value: p == null ? ProfileController() : ProfileController.seeded(p),
        ),
        ChangeNotifierProvider<DiaryRepository>.value(value: diary),
        ChangeNotifierProvider(create: (_) => WeightController()),
        ChangeNotifierProvider(create: (_) => WaterController()),
        ChangeNotifierProvider(create: (_) => UnitController()),
        ChangeNotifierProvider(create: (_) => MeasurementsController()),
        ChangeNotifierProvider(create: (_) => PointsController()),
        ChangeNotifierProvider(create: (_) => MealPlanController()),
        ChangeNotifierProvider(create: (_) => RecentFoodsController()),
        ChangeNotifierProvider(create: (_) => ActivityController()),
        ChangeNotifierProvider(create: (_) => FastingController()),
        ChangeNotifierProvider(create: (_) => RecipeController()),
        ChangeNotifierProxyProvider4<DiaryRepository, WaterController,
            WeightController, PointsController, DailyTasksController>(
          create: (ctx) => DailyTasksController(
            diary: ctx.read<DiaryRepository>(),
            water: ctx.read<WaterController>(),
            weight: ctx.read<WeightController>(),
            points: ctx.read<PointsController>(),
          ),
          update: (_, d, w, wt, pts, prev) =>
              prev ?? DailyTasksController(diary: d, water: w, weight: wt, points: pts),
        ),
      ],
      child: MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: buildTheme(ZadPalette.energy),
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          minScaleFactor: textScale,
          maxScaleFactor: textScale,
          child: child!,
        ),
        home: screen,
      ),
    ),
  );
  return diary;
}

/// ينهي كل الحركات ثم يهدم الشجرة.
/// بلا الهدم يبقى مؤقّت `flutter_animate` معلّقاً ويفشل الاختبار،
/// وبلا الاستقرار تبقى الأرقام المتحرّكة على قيمتها الابتدائية.
Future<void> settleAndDispose(WidgetTester tester) async {
  await tester.pumpAndSettle(const Duration(milliseconds: 50));
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

Meal testMeal(
  String name, {
  int cal = 400,
  MealType type = MealType.lunch,
  DateTime? at,
}) =>
    Meal(
      id: '$name-${at?.millisecondsSinceEpoch ?? 0}',
      name: name,
      calories: cal,
      macros: const Macros(protein: 25, carbs: 40, fat: 12),
      time: at ?? DateTime.now(),
      type: type,
    );
