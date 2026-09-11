import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zad/core/dates.dart';
import 'package:zad/data/diary_repository.dart';
import 'package:zad/data/local_diary_repository.dart';
import 'package:zad/models/meal.dart';

const _goal = DailyGoal(calories: 2000, macros: Macros(protein: 150, carbs: 200, fat: 60));

Meal _meal(String id, {int cal = 300, MealType type = MealType.lunch, DateTime? at}) => Meal(
      id: id,
      name: 'وجبة $id',
      calories: cal,
      macros: const Macros(protein: 20, carbs: 30, fat: 10),
      time: at ?? DateTime.now(),
      type: type,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('المستودع المحلي (وضع بلا إنترنت)', () {
    test('يسجّل ويحسب المستهلك والمتبقّي', () {
      final r = LocalDiaryRepository(goal: _goal);
      r.addMeal(_meal('a', cal: 500));
      r.addMeal(_meal('b', cal: 300));
      expect(r.todayMeals.length, 2);
      expect(r.consumedCalories, 800);
      expect(r.remainingCalories, 1200);
    });

    test('الحذف يشيل الوجبة الصحيحة فقط', () {
      final r = LocalDiaryRepository(goal: _goal);
      final a = _meal('a');
      r.addMeal(a);
      r.addMeal(_meal('b'));
      r.removeMeal(a);
      expect(r.todayMeals.single.id, 'b');
    });

    test('البيانات تبقى بعد إعادة التشغيل', () async {
      final first = LocalDiaryRepository(goal: _goal);
      first.addMeal(_meal('a', cal: 450));
      await Future<void>.delayed(const Duration(milliseconds: 30));

      final second = LocalDiaryRepository(goal: _goal);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(second.consumedCalories, 450);
    });

    test('كل يوم منفصل — اختيار يوم آخر يعرض وجباته', () async {
      final r = LocalDiaryRepository(goal: _goal);
      r.addMeal(_meal('today'));
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      r.selectDate(yesterday);
      expect(r.todayMeals, isEmpty);
      r.addMeal(_meal('yest'));
      expect(r.todayMeals.single.id, 'yest');
      expect((await r.getMealsForDay(DateTime.now())).single.id, 'today');
    });

    test('الستريك يحتسب اليوم ولا ينكسر بيوم فارغ جارٍ', () {
      final r = LocalDiaryRepository(goal: _goal);
      // اليوم فقط
      r.addMeal(_meal('t'));
      expect(r.streakDays, 1, reason: 'تسجيل اليوم لازم يعطي ستريك 1 مو 0');

      // اليوم + أمس
      r.selectDate(DateTime.now().subtract(const Duration(days: 1)));
      r.addMeal(_meal('y'));
      r.selectDate(DateTime.now());
      expect(r.streakDays, 2);
    });

    test('يوم فارغ اليوم مع تسجيل أمس يبقي الستريك قائماً', () {
      final r = LocalDiaryRepository(goal: _goal);
      r.selectDate(DateTime.now().subtract(const Duration(days: 1)));
      r.addMeal(_meal('y'));
      r.selectDate(DateTime.now());
      expect(r.todayMeals, isEmpty);
      expect(r.streakDays, 1, reason: 'اليوم ما انتهى — ما يكسر السلسلة');
    });

    test('snapshot يعطي كل ما يحتاجه الترحيل', () {
      final r = LocalDiaryRepository(goal: _goal);
      r.addMeal(_meal('a'));
      final snap = r.snapshot();
      expect(snap.length, 1);
      expect(snap.values.single.single.id, 'a');
    });
  });

  group('المستودع الوهمي', () {
    test('فارغ افتراضياً — لا بيانات تجريبية للمستخدم الحقيقي', () {
      final r = MockDiaryRepository();
      expect(r.todayMeals, isEmpty);
      expect(r.consumedCalories, 0);
      expect(r.streakDays, 0);
      expect(r.userName, '');
    });

    test('seeded: true يعبّي بيانات العرض للاختبارات', () {
      final r = MockDiaryRepository(seeded: true);
      expect(r.todayMeals, isNotEmpty);
    });
  });

  group('استعلام المدى (تقويم الشهر)', () {
    test('يرجّع سعرات كل يوم بمفتاح اليوم', () async {
      final r = LocalDiaryRepository(goal: _goal);
      final d1 = DateTime.now().subtract(const Duration(days: 2));
      final d2 = DateTime.now().subtract(const Duration(days: 1));
      r.selectDate(d1);
      r.addMeal(_meal('a', cal: 600));
      r.selectDate(d2);
      r.addMeal(_meal('b', cal: 400));
      r.addMeal(_meal('c', cal: 100));

      final map = await r.getCaloriesForRange(d1, DateTime.now());
      expect(map[dayKey(d1)], 600);
      expect(map[dayKey(d2)], 500);
      expect(map[dayKey(DateTime.now())], 0);
    });

    test('لا يجلب أياماً مستقبلية', () async {
      final r = LocalDiaryRepository(goal: _goal);
      final future = DateTime.now().add(const Duration(days: 5));
      final map = await r.getCaloriesForRange(DateTime.now(), future);
      expect(map.containsKey(dayKey(future)), isFalse);
      expect(map.length, 1);
    });
  });
}
