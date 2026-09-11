import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zad/data/daily_tasks_controller.dart';
import 'package:zad/data/diary_repository.dart';
import 'package:zad/data/local_diary_repository.dart';
import 'package:zad/data/points_controller.dart';
import 'package:zad/data/water_controller.dart';
import 'package:zad/data/weight_controller.dart';
import 'package:zad/models/meal.dart';

const _goal = DailyGoal(calories: 2000, macros: Macros(protein: 150, carbs: 200, fat: 60));

Meal _meal(String id, MealType type) => Meal(
      id: id,
      name: id,
      calories: 400,
      macros: const Macros(protein: 25, carbs: 40, fat: 12),
      time: DateTime.now(),
      type: type,
    );

/// ينتظر انتهاء `_loadAwarded` غير المتزامن داخل المتحكّم.
Future<DailyTasksController> _ready(DiaryRepository diary) async {
  final c = DailyTasksController(
    diary: diary,
    water: WaterController(),
    weight: WeightController(),
    points: PointsController(),
  );
  await Future<void>.delayed(const Duration(milliseconds: 40));
  return c;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('تسجيل الوجبات الثلاث يكمل المهام ويمنح نقاطاً', () async {
    final diary = LocalDiaryRepository(goal: _goal);
    final points = PointsController();
    final ctrl = DailyTasksController(
      diary: diary,
      water: WaterController(),
      weight: WeightController(),
      points: points,
    );
    await Future<void>.delayed(const Duration(milliseconds: 40));

    diary.addMeal(_meal('b', MealType.breakfast));
    diary.addMeal(_meal('l', MealType.lunch));
    diary.addMeal(_meal('d', MealType.dinner));
    ctrl.checkAndAward();

    final done = ctrl.tasks.where((t) => t.isDone).map((t) => t.type).toSet();
    expect(done, contains(DailyTaskType.logBreakfast));
    expect(done, contains(DailyTaskType.logAllMeals));
    expect(points.total, greaterThan(0));
  });

  test('المهمة الواحدة تُمنح مرة واحدة فقط مهما تكرّر الفحص', () async {
    final diary = LocalDiaryRepository(goal: _goal);
    final points = PointsController();
    final ctrl = DailyTasksController(
      diary: diary,
      water: WaterController(),
      weight: WeightController(),
      points: points,
    );
    await Future<void>.delayed(const Duration(milliseconds: 40));

    diary.addMeal(_meal('b', MealType.breakfast));
    ctrl.checkAndAward();
    final after = points.total;
    ctrl.checkAndAward();
    ctrl.checkAndAward();
    expect(points.total, after, reason: 'تكرار الفحص ما يضاعف النقاط');
  });

  test('تصفّح يوم سابق لا يمنح أي نقاط', () async {
    final diary = LocalDiaryRepository(goal: _goal);
    final points = PointsController();
    final ctrl = DailyTasksController(
      diary: diary,
      water: WaterController(),
      weight: WeightController(),
      points: points,
    );
    await Future<void>.delayed(const Duration(milliseconds: 40));

    // يوم سابق مليء بالوجبات
    diary.selectDate(DateTime.now().subtract(const Duration(days: 3)));
    diary.addMeal(_meal('b', MealType.breakfast));
    diary.addMeal(_meal('l', MealType.lunch));
    diary.addMeal(_meal('d', MealType.dinner));

    ctrl.checkAndAward();
    expect(points.total, 0,
        reason: 'لولا الحارس لأمكن تكديس النقاط بتصفّح الأيام السابقة');
  });

  test('قبل تحميل سجلّ المنح لا تُمنح نقاط (يمنع المنح المزدوج)', () {
    final diary = LocalDiaryRepository(goal: _goal);
    final points = PointsController();
    final ctrl = DailyTasksController(
      diary: diary,
      water: WaterController(),
      weight: WeightController(),
      points: points,
    );
    diary.addMeal(_meal('b', MealType.breakfast));
    ctrl.checkAndAward(); // لم يكتمل _loadAwarded بعد
    expect(points.total, 0);
  });

  test('usesSameSources يميّز تبديل المستودع', () async {
    final a = LocalDiaryRepository(goal: _goal);
    final b = LocalDiaryRepository(goal: _goal);
    final ctrl = await _ready(a);
    expect(ctrl.usesSameSources(a), isTrue);
    expect(ctrl.usesSameSources(b), isFalse);
  });
}
