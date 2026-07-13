import 'package:flutter/material.dart';

import '../models/detraining.dart';
import '../models/meal.dart';
import '../models/user_profile.dart';
import '../theme/app_palette.dart';

/// نظام الترجمة — عربي/إنجليزي. كل نص بالواجهة يمر من هنا (صفر نص ثابت).
/// الاتجاه (RTL/LTR) يتحدّد تلقائياً من اللغة عبر MaterialApp.
class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  bool get isAr => locale.languageCode == 'ar';

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const supportedLocales = [Locale('ar'), Locale('en')];

  String _(String ar, String en) => isAr ? ar : en;

  // عام
  String get greeting => _('مساء الخير', 'Good evening');
  String get caloriesLeft => _('سعرة متبقية', 'kcal left');
  String get calorieUnit => _('سعرة', 'kcal');
  String get todayMeals => _('وجبات اليوم', "Today's meals");
  String get breakfast => _('فطور', 'Breakfast');
  String get lunch => _('غداء', 'Lunch');
  String get dinner => _('عشاء', 'Dinner');
  String get snack => _('سناك', 'Snack');
  String get addFood => _('أضف طعام', 'Add food');
  String mealTypeLabel(MealType t) => switch (t) {
    MealType.breakfast => breakfast,
    MealType.lunch => lunch,
    MealType.dinner => dinner,
    MealType.snack => snack,
  };
  String get comingSoon => _('قريباً', 'Coming soon');

  // ماكروز
  String get protein => _('بروتين', 'Protein');
  String get carbs => _('كارب', 'Carbs');
  String get fat => _('دهون', 'Fat');
  String get proteinShort => _('ب', 'P');
  String get carbsShort => _('ك', 'C');
  String get fatShort => _('د', 'F');

  // تبويبات
  String get tabHome => _('الرئيسية', 'Home');
  String get tabAnalytics => _('الإحصاء', 'Stats');
  String get tabAssistant => _('المساعد', 'Assistant');
  String get tabMap => _('الخريطة', 'Map');
  String get tabChallenges => _('التحديات', 'Challenges');

  // رانك / نقاط
  String get points => _('نقطة', 'pts');
  String get yourRank => _('رانكك', 'Your rank');
  String get activeChallenges => _('تحديات نشطة', 'Active challenges');
  String get leaderboard => _('لوحة الصدارة', 'Leaderboard');
  String get weeklyLeague => _('الدوري الأسبوعي', 'Weekly league');
  String get silverLeague => _('فضة', 'Silver');
  String get you => _('أنت', 'You');
  String plusPoints(int p) => '+$p ${_('نقطة', 'pts')}';
  String get lbs => _('رطل', 'lbs');
  String get unitToggle => _('وحدة الوزن', 'Weight unit');

  // إعدادات
  String get appearance => _('المظهر', 'Appearance');
  String get language => _('اللغة', 'Language');
  String get arabic => _('العربية', 'Arabic');
  String get english => _('الإنجليزية', 'English');

  // المساعد
  String get assistantHint => _('اكتب أكلة… مثل: كبسة دجاج', 'Type a food… e.g. chicken kabsa');
  String get assistantEmpty =>
      _('اكتب أي أكلة وأقدّر سعراتها', "Type any food and I'll estimate its calories");
  String get verified => _('موثّق', 'Verified');
  String get approximate => _('تقديري', 'Approximate');
  String get addToDiary => _('أضف لليوم', 'Add to diary');
  String get added => _('أُضيفت ✓', 'Added ✓');
  String get thinking => _('أفكّر…', 'Thinking…');
  String get aiNotReady =>
      _('الذكاء غير مفعّل — أضف مفتاح Groq', 'AI not enabled — add a Groq key');
  String get tryAgain => _('صار خطأ، جرّب مرة ثانية', 'Something went wrong, try again');

  // التحديات
  String dayStreak(int n) => _('$n يوم متتالي', '$n-day streak');

  // placeholders
  String get assistantTitle => _('المساعد رفيق', 'Rafiq Assistant');
  String get assistantSub =>
      _('سجّل أكلك بالكلام واسأل عن سعراتك', 'Log food by chatting and ask about your calories');
  String get mapTitle => _('اقتراح المطاعم', 'Restaurant suggestions');
  String get mapSub =>
      _('مطاعم قريبة بوجبات تناسب سعراتك المتبقية', 'Nearby meals that fit your remaining macros');
  String get challengesTitle => _('التحديات', 'Challenges');
  String get challengesSub =>
      _('تحديات ولوحة صدارة ودوريات', 'Challenges, leaderboards and leagues');

  // تسجيل وجبة
  String get addMeal => _('تسجيل وجبة', 'Add meal');
  String get searchFood => _('دوّر عن أكلة…', 'Search food…');
  String get noFoodMatch =>
      _('ما لقينا الصنف — جرّب المساعد بالكتابة', 'Not found — try typing in the assistant');
  String get grams => _('جرام', 'g');
  String get add => _('أضف', 'Add');

  // الوزن
  String get weightTracking => _('تتبّع الوزن', 'Weight tracking');
  String get currentWeight => _('وزنك الحالي', 'Current weight');
  String get logWeight => _('سجّل وزن', 'Log weight');
  String get bmiLabel => _('مؤشر الكتلة', 'BMI');
  String get noWeightYet => _('ما فيه سجلّات وزن بعد', 'No weight logs yet');
  String get kg => _('كجم', 'kg');
  String bmiCategory(double bmi) {
    if (bmi < 18.5) return _('نقص', 'Underweight');
    if (bmi < 25) return _('طبيعي', 'Normal');
    if (bmi < 30) return _('زائد', 'Overweight');
    return _('سمنة', 'Obese');
  }

  // الماء
  String get water => _('الماء', 'Water');
  String get cups => _('أكواب', 'cups');

  // الملف
  String get profile => _('الملف الشخصي', 'Profile');
  String get editGoal => _('عدّل الهدف', 'Edit goal');
  String get about => _('عن التطبيق', 'About');
  String get save => _('حفظ', 'Save');

  // المطاعم
  String get nearbyRestaurants => _('مطاعم قريبة', 'Nearby restaurants');
  String get suggestMeal => _('اقترح وجبة تناسبني', 'Suggest a meal for me');
  String get remainingToday => _('متبقّي اليوم', 'Remaining today');
  String get away => _('يبعد', 'away');

  // حاسبة العودة بعد انقطاع
  String get comebackTitle => _('العودة بعد انقطاع', 'Return after a break');
  String get comebackSub => _(
      'انقطعت عن التمرين؟ نقدّر تراجعك ونقترح بداية آمنة',
      'Took a break? We estimate your decline and suggest a safe restart');
  String get weeksOffQ => _('كم أسبوع انقطعت؟', 'Weeks off?');
  String get experienceQ => _('خبرتك بالتمرين', 'Training experience');
  String get reasonQ => _('السبب', 'Reason');
  String get strengthLoss => _('تراجع القوة', 'Strength');
  String get muscleLoss => _('تراجع العضلات', 'Muscle');
  String get cardioLoss => _('تراجع اللياقة', 'Cardio');
  String get startAtLabel => _('ابدأ بـ', 'Start at');
  String get ofPrevious => _('من وزنك السابق', 'of previous weight');
  String get recoveryTime => _('تقدير العودة لمستواك', 'Time to regain level');
  String get weeksUnit => _('أسبوع', 'weeks');
  String get detrainingDisclaimer => _(
      'تقديري بناءً على أبحاث عامة، يختلف من شخص لآخر. ابدأ متحفّظاً — الأوتار تتأقلم أبطأ من العضلات. للإصابات راجع مختصاً قبل العودة.',
      'Estimate from general research; varies per person. Start conservatively — tendons adapt slower than muscles. For injuries, consult a specialist before returning.');

  String experienceLabel(TrainingExperience e) => switch (e) {
        TrainingExperience.beginner => _('مبتدئ', 'Beginner'),
        TrainingExperience.intermediate => _('متوسط', 'Intermediate'),
        TrainingExperience.advanced => _('متقدّم', 'Advanced'),
      };

  String reasonLabel(BreakReason r) => switch (r) {
        BreakReason.travel => _('سفر', 'Travel'),
        BreakReason.exams => _('اختبارات', 'Exams'),
        BreakReason.injury => _('إصابة', 'Injury'),
        BreakReason.other => _('آخر', 'Other'),
      };

  // onboarding
  String get welcome => _('أهلاً بك في زاد', 'Welcome to Zad');
  String get onboardingSub =>
      _('جاوب بسرعة ونحسب هدفك اليومي', "A few quick questions to set your daily target");
  String get nameQ => _('وش اسمك؟', "What's your name?");
  String get namePlaceholder => _('اسمك', 'Your name');
  String get genderQ => _('الجنس', 'Gender');
  String get male => _('ذكر', 'Male');
  String get female => _('أنثى', 'Female');
  String get ageQ => _('العمر', 'Age');
  String get heightQ => _('الطول (سم)', 'Height (cm)');
  String get weightQ => _('الوزن (كجم)', 'Weight (kg)');
  String get activityQ => _('مستوى نشاطك', 'Activity level');
  String get goalQ => _('هدفك', 'Your goal');
  String get yourTarget => _('هدفك اليومي', 'Your daily target');
  String get startApp => _('يلا نبدأ', "Let's start");
  String get enterName => _('اكتب اسمك أول', 'Enter your name first');

  String activityLabel(ActivityLevel a) => switch (a) {
        ActivityLevel.sedentary => _('خامل', 'Sedentary'),
        ActivityLevel.light => _('خفيف', 'Light'),
        ActivityLevel.moderate => _('متوسط', 'Moderate'),
        ActivityLevel.active => _('نشيط', 'Active'),
      };

  String goalLabel(GoalType g) => switch (g) {
        GoalType.lose => _('إنقاص وزن', 'Lose weight'),
        GoalType.maintain => _('محافظة', 'Maintain'),
        GoalType.gain => _('زيادة وزن', 'Gain weight'),
      };

  String paletteLabel(ZadPalette p) => switch (p) {
        ZadPalette.energy => _('طاقة', 'Energy'),
        ZadPalette.luxe => _('فخم', 'Luxe'),
        ZadPalette.clean => _('نظيف', 'Clean'),
        ZadPalette.gulf => _('خليجي', 'Gulf'),
      };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['ar', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
