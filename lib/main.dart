import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

import 'core/motion.dart';
import 'data/daily_tasks_controller.dart';
import 'data/diary_repository.dart';
import 'data/meal_plan_controller.dart';
import 'data/firestore_diary_repository.dart';
import 'data/measurements_controller.dart';
import 'data/points_controller.dart';
import 'data/unit_controller.dart';
import 'models/meal.dart';
import 'data/profile_controller.dart';
import 'data/water_controller.dart';
import 'data/weight_controller.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/shell/app_shell.dart';
import 'l10n/app_localizations.dart';
import 'l10n/locale_controller.dart';
import 'services/food_lookup.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.init();
  final user = FirebaseAuth.instance.currentUser ??
      (await FirebaseAuth.instance.signInAnonymously()).user!;
  final themeController = ThemeController()..load();
  final localeController = LocaleController()..load();
  final profileController = ProfileController()..load();
  runApp(ZadApp(
    themeController: themeController,
    localeController: localeController,
    profileController: profileController,
    userId: user.uid,
  ));
}

class ZadApp extends StatelessWidget {
  final ThemeController themeController;
  final LocaleController localeController;
  final ProfileController profileController;
  final String userId;
  const ZadApp({
    super.key,
    required this.themeController,
    required this.localeController,
    required this.profileController,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeController),
        ChangeNotifierProvider.value(value: localeController),
        ChangeNotifierProvider.value(value: profileController),
        ChangeNotifierProxyProvider<ProfileController, DiaryRepository>(
          create: (_) => MockDiaryRepository(),
          update: (_, profile, prev) {
            final p = profile.profile;
            // بلا ملف أو بلا Firebase (اختبارات/فشل تهيئة): نبقى على Mock.
            if (p == null || Firebase.apps.isEmpty) {
              return prev ?? MockDiaryRepository();
            }
            // نعيد استخدام الـ repo القائم إن لم يتغيّر شيء — وإلا نتخلص منه.
            if (prev is FirestoreDiaryRepository &&
                prev.goal.calories == p.targetCalories &&
                prev.userName == p.name) {
              return prev;
            }
            prev?.dispose();
            return FirestoreDiaryRepository(
              userId: userId,
              goal: DailyGoal(
                calories: p.targetCalories,
                macros: p.targetMacros,
              ),
              name: p.name,
            );
          },
        ),
        ChangeNotifierProvider(create: (_) => WeightController()..load()),
        ChangeNotifierProvider(create: (_) => WaterController()..load()),
        ChangeNotifierProvider(create: (_) => UnitController()..load()),
        ChangeNotifierProvider(create: (_) => MeasurementsController()..load()),
        ChangeNotifierProvider(create: (_) => PointsController()..load()),
        ChangeNotifierProxyProvider4<DiaryRepository, WaterController, WeightController, PointsController,
            DailyTasksController>(
          create: (ctx) => DailyTasksController(
            diary: ctx.read<DiaryRepository>(),
            water: ctx.read<WaterController>(),
            weight: ctx.read<WeightController>(),
            points: ctx.read<PointsController>(),
          ),
          update: (_, diary, water, weight, points, prev) {
            final ctrl = prev ??
                DailyTasksController(
                    diary: diary, water: water, weight: weight, points: points);
            ctrl.checkAndAward();
            return ctrl;
          },
        ),
        ChangeNotifierProvider(create: (_) => MealPlanController()..load()),
        Provider<FoodLookup>(create: (_) => FoodLookup()),
      ],
      child: Consumer2<ThemeController, LocaleController>(
        builder: (context, theme, locale, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'زاد',
            scrollBehavior: const ZadScrollBehavior(),

            // التبديل بين الثيمات الأربعة يتمايل بسلاسة عبر هذا الانتقال.
            theme: buildTheme(theme.palette),
            themeAnimationDuration: const Duration(milliseconds: 500),
            themeAnimationCurve: Curves.easeInOut,

            // اللغة — الاتجاه RTL/LTR يضبط تلقائياً.
            locale: locale.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            home: const _Root(),
          );
        },
      ),
    );
  }
}

/// يقرّر: onboarding (أول مرة) أو القشرة الرئيسية.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final onboarded = context.watch<ProfileController>().onboarded;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: onboarded ? const AppShell() : const OnboardingScreen(),
    );
  }
}
