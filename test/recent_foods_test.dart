import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zad/data/recent_foods_controller.dart';
import 'package:zad/models/meal.dart';

Meal _meal(String name, {int cal = 100}) => Meal(
      id: name,
      name: name,
      calories: cal,
      macros: const Macros(protein: 10, carbs: 10, fat: 5),
      time: DateTime.now(),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('تسجيل صنف يضيفه للأخيرة', () async {
    final c = RecentFoodsController();
    await c.record(_meal('كبسة'), grams: 300);
    expect(c.recents.length, 1);
    expect(c.recents.first.name, 'كبسة');
    expect(c.recents.first.grams, 300);
  });

  test('تكرار نفس الصنف والكمية يرفع العدّاد ولا يكرّر الصف', () async {
    final c = RecentFoodsController();
    await c.record(_meal('كبسة'), grams: 300);
    await c.record(_meal('كبسة'), grams: 300);
    expect(c.recents.length, 1);
    expect(c.recents.first.useCount, 2);
  });

  test('نفس الصنف بكمية مختلفة = إدخال منفصل', () async {
    final c = RecentFoodsController();
    await c.record(_meal('كبسة'), grams: 300);
    await c.record(_meal('كبسة'), grams: 150);
    expect(c.recents.length, 2);
  });

  test('الأحدث يظهر أولاً', () async {
    final c = RecentFoodsController();
    await c.record(_meal('أول'), grams: 100);
    await c.record(_meal('ثاني'), grams: 100);
    expect(c.recents.first.name, 'ثاني');
  });

  test('المفضّلة تُرتّب بالأكثر استخداماً', () async {
    final c = RecentFoodsController();
    await c.record(_meal('قليل'), grams: 100);
    await c.record(_meal('كثير'), grams: 100);
    await c.record(_meal('كثير'), grams: 100);
    await c.toggleFavorite(c.recents.firstWhere((f) => f.name == 'قليل'));
    await c.toggleFavorite(c.recents.firstWhere((f) => f.name == 'كثير'));
    expect(c.favorites.first.name, 'كثير');
    expect(c.favorites.length, 2);
  });

  test('المفضّلة لا تُحذف عند تجاوز حد الأخيرة', () async {
    final c = RecentFoodsController();
    await c.record(_meal('مفضّل'), grams: 100);
    await c.toggleFavorite(c.recents.first);
    for (var i = 0; i < 40; i++) {
      await c.record(_meal('صنف$i'), grams: 100);
    }
    expect(c.recents.any((f) => f.name == 'مفضّل'), isTrue);
    expect(c.recents.length, lessThanOrEqualTo(31));
  });

  test('البيانات تُحفظ وتُقرأ بعد إعادة التحميل', () async {
    final a = RecentFoodsController();
    await a.record(_meal('محفوظ'), grams: 250);
    await a.toggleFavorite(a.recents.first);

    final b = RecentFoodsController();
    await b.load();
    expect(b.recents.length, 1);
    expect(b.recents.first.name, 'محفوظ');
    expect(b.recents.first.grams, 250);
    expect(b.favorites.length, 1);
  });

  test('الحذف يزيل الصنف والمفضّلة معاً', () async {
    final c = RecentFoodsController();
    await c.record(_meal('يُحذف'), grams: 100);
    await c.toggleFavorite(c.recents.first);
    await c.remove(c.recents.first);
    expect(c.recents, isEmpty);
    expect(c.favorites, isEmpty);
  });
}
