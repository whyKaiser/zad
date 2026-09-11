import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

import 'core/motion.dart';
import 'data/activity_controller.dart';
import 'data/auth_controller.dart';
import 'data/daily_tasks_controller.dart';
import 'data/diary_repository.dart';
import 'data/firestore_diary_repository.dart';
import 'data/local_diary_repository.dart';
import 'data/meal_plan_controller.dart';
import 'data/measurements_controller.dart';
import 'data/points_controller.dart';
import 'data/profile_controller.dart';
import 'data/recent_foods_controller.dart';
import 'data/unit_controller.dart';
import 'data/water_controller.dart';
import 'data/weight_controller.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/shell/app_shell.dart';
import 'l10n/app_localizations.dart';
import 'l10n/locale_controller.dart';
import 'models/meal.dart';
import 'services/diary_migrator.dart';
import 'services/food_lookup.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // لا شيء في الإقلاع يحق له إسقاط التطبيق — أول تشغيل قد يكون بلا إنترنت.
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    // تخزين محلي لـ Firestore: التطبيق يشتغل كاملاً بلا شبكة والكتابات تُرسَل لاحقاً.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  try {
    await NotificationService.init();
  } catch (e) {
    debugPrint('Notifications init failed: $e');
  }

  final auth = AuthController();
  await auth.init(); // لا يرمي — يعيد المحاولة داخلياً

  runApp(ZadApp(
    authController: auth,
    themeController: ThemeController()..load(),
    localeController: LocaleController()..load(),
    profileController: ProfileController()..load(),
  ));
}

class ZadApp extends StatelessWidget {
  final AuthController authController;
  final ThemeController themeController;
  final LocaleController localeController;
  final ProfileController profileController;

  const ZadApp({
    super.key,
    required this.authController,
    required this.themeController,
    required this.localeController,
    required this.profileController,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeController),
        ChangeNotifierProvider.value(value: localeController),
        ChangeNotifierProvider.value(value: profileController),
        ChangeNotifierProvider.value(value: authController),

        // اليوميات تتبع الملف والمصادقة معاً:
        //   بلا ملف → Mock فارغ · بلا دخول → محلي يُحفظ · بعد الدخول → سحابي.
        ChangeNotifierProxyProvider2<ProfileController, AuthController, DiaryRepository>(
          create: (_) => MockDiaryRepository(),
          update: (_, profile, auth, prev) {
            final p = profile.profile;
            if (p == null) return prev is MockDiaryRepository ? prev : MockDiaryRepository();

            final goal = DailyGoal(calories: p.targetCalories, macros: p.targetMacros);
            final uid = auth.uid;

            if (uid == null || Firebase.apps.isEmpty) {
              if (prev is LocalDiaryRepository && prev.goal.calories == goal.calories) {
                return prev;
              }
              prev?.dispose();
              return LocalDiaryRepository(goal: goal, name: p.name);
            }

            // انتقال من المحلي للسحابي: نرحّل ما سُجّل بلا إنترنت قبل التبديل.
            if (prev is LocalDiaryRepository) {
              DiaryMigrator.migrate(userId: uid, local: prev.snapshot());
            } else if (prev is FirestoreDiaryRepository &&
                prev.userId == uid &&
                prev.goal.calories == goal.calories &&
                prev.userName == p.name) {
              return prev;
            }

            prev?.dispose();
            return FirestoreDiaryRepository(userId: uid, goal: goal, name: p.name);
          },
        ),

        ChangeNotifierProvider(create: (_) => WeightController()..load()),
        ChangeNotifierProvider(create: (_) => WaterController()..load()),
        ChangeNotifierProvider(create: (_) => UnitController()..load()),
        ChangeNotifierProvider(create: (_) => MeasurementsController()..load()),
        ChangeNotifierProvider(create: (_) => PointsController()..load()),
        ChangeNotifierProvider(create: (_) => MealPlanController()..load()),
        ChangeNotifierProvider(create: (_) => RecentFoodsController()..load()),
        ChangeNotifierProvider(create: (_) => ActivityController()..load()),
        ChangeNotifierProxyProvider4<DiaryRepository, WaterController, WeightController,
            PointsController, DailyTasksController>(
          create: (ctx) => DailyTasksController(
            diary: ctx.read<DiaryRepository>(),
            water: ctx.read<WaterController>(),
            weight: ctx.read<WeightController>(),
            points: ctx.read<PointsController>(),
          ),
          update: (_, diary, water, weight, points, prev) {
            if (prev == null || !prev.usesSameSources(diary)) {
              prev?.dispose();
              return DailyTasksController(
                  diary: diary, water: water, weight: weight, points: points)
                ..checkAndAward();
            }
            prev.checkAndAward();
            return prev;
          },
        ),
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
