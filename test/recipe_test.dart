import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zad/data/food_seed.dart';
import 'package:zad/data/recipe_controller.dart';
import 'package:zad/models/meal.dart';

/// أول صنفين من القاعدة — نستعملهما بدل أسماء ثابتة قد تتغيّر.
final _a = kFoodSeed[0];
final _b = kFoodSeed[1];

Recipe _recipe({int servings = 2, List<RecipeIngredient>? items}) => Recipe(
      id: 'r1',
      name: 'وصفتي',
      servings: servings,
      ingredients: items ??
          [
            RecipeIngredient(foodId: _a.id, grams: 200),
            RecipeIngredient(foodId: _b.id, grams: 100),
          ],
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('حساب المكوّن', () {
    test('السعرات تتناسب مع الكمية', () {
      final full = RecipeIngredient(foodId: _a.id, grams: 100);
      final half = RecipeIngredient(foodId: _a.id, grams: 50);
      expect(full.calories, _a.kcalPer100g);
      expect(half.calories, closeTo(_a.kcalPer100g / 2, 1));
    });

    test('صنف محذوف من القاعدة لا يُسقط الحساب', () {
      const ghost = RecipeIngredient(foodId: 'صنف_غير_موجود', grams: 100);
      expect(ghost.calories, 0);
      expect(ghost.macros.protein, 0);
      expect(ghost.name(isAr: true), 'صنف_غير_موجود');
    });
  });

  group('حساب الوصفة', () {
    test('المجموع = مجموع المكوّنات', () {
      final r = _recipe();
      final expected =
          r.ingredients.fold<int>(0, (a, i) => a + i.calories);
      expect(r.totalCalories, expected);
      expect(r.totalGrams, 300);
    });

    test('نصيب الحصة = المجموع ÷ عدد الحصص', () {
      final r = _recipe(servings: 2);
      expect(r.caloriesPerServing, (r.totalCalories / 2).round());
    });

    test('عدد حصص صفر أو سالب لا يُنتج قسمة على صفر', () {
      final zero = _recipe(servings: 0);
      expect(zero.caloriesPerServing, zero.totalCalories);
      expect(zero.caloriesPerServing.isFinite, isTrue);

      final negative = _recipe(servings: -3);
      expect(negative.caloriesPerServing, negative.totalCalories);
    });

    test('وصفة بلا مكوّنات = أصفار بلا انهيار', () {
      final empty = _recipe(items: []);
      expect(empty.totalCalories, 0);
      expect(empty.caloriesPerServing, 0);
      expect(empty.macrosPerServing.protein, 0);
    });
  });

  group('التحويل لوجبة', () {
    test('حصة واحدة تحمل اسم الوصفة بلا لاحقة', () {
      final m = _recipe().toMeal(type: MealType.lunch, time: DateTime(2026, 5, 1));
      expect(m.name, 'وصفتي');
      expect(m.type, MealType.lunch);
      expect(m.calories, _recipe().caloriesPerServing);
    });

    test('حصتان تضاعفان القيم وتظهران في الاسم', () {
      final r = _recipe();
      final m = r.toMeal(type: MealType.dinner, time: DateTime(2026, 5, 1), count: 2);
      expect(m.calories, r.caloriesPerServing * 2);
      expect(m.name, contains('×2'));
    });

    test('نصف حصة تُعرض بكسر عشري واحد', () {
      final m = _recipe()
          .toMeal(type: MealType.snack, time: DateTime(2026, 5, 1), count: 0.5);
      expect(m.name, contains('×0.5'));
    });

    test('الوقت المعطى يُحترم (تسجيل ليوم سابق)', () {
      final past = DateTime(2026, 1, 2, 13, 30);
      final m = _recipe().toMeal(type: MealType.lunch, time: past);
      expect(m.time, past);
    });
  });

  group('التخزين', () {
    test('الحفظ ثم التحميل يُرجع الوصفة كاملة', () async {
      final a = RecipeController();
      await a.save(_recipe());

      final b = RecipeController();
      await b.load();
      expect(b.recipes.length, 1);
      final r = b.recipes.single;
      expect(r.name, 'وصفتي');
      expect(r.servings, 2);
      expect(r.ingredients.length, 2);
      expect(r.ingredients.first.grams, 200);
    });

    test('الحفظ بنفس المعرّف يحدّث ولا يكرّر', () async {
      final c = RecipeController();
      await c.save(_recipe());
      await c.save(_recipe(servings: 4));
      expect(c.recipes.length, 1);
      expect(c.recipes.single.servings, 4);
    });

    test('الحذف يزيلها من التخزين أيضاً', () async {
      final a = RecipeController();
      await a.save(_recipe());
      await a.remove(a.recipes.single);

      final b = RecipeController();
      await b.load();
      expect(b.recipes, isEmpty);
    });

    test('تخزين تالف لا يعطّل الميزة', () async {
      SharedPreferences.setMockInitialValues({'zad_recipes': 'ليس JSON'});
      final c = RecipeController();
      await c.load();
      expect(c.recipes, isEmpty);
      // يقدر يحفظ بعدها عادي
      await c.save(_recipe());
      expect(c.recipes.length, 1);
    });
  });
}
