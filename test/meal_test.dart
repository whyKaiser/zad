import 'package:flutter_test/flutter_test.dart';
import 'package:zad/models/meal.dart';

Meal _meal(String name) => Meal(
      id: 'x',
      name: name,
      calories: 100,
      macros: const Macros(protein: 5, carbs: 10, fat: 2),
      time: DateTime(2026, 5, 1, 12),
      type: MealType.lunch,
    );

void main() {
  test('الحقول المخزَّنة تطابق ما تسمح به قواعد Firestore', () {
    final json = _meal('كبسة').toJson();
    expect(
      json.keys.toSet(),
      {'id', 'name', 'calories', 'protein', 'carbs', 'fat', 'time', 'type'},
    );
    expect(json['calories'], isA<int>());
    expect(json['protein'], isA<int>());
    expect(json['type'], 'lunch');
    expect((json['time'] as String).length, lessThanOrEqualTo(40));
  });

  test('الاسم الطويل يُقصَّ حتى لا تُرفض الكتابة بصمت', () {
    final long = 'ط' * 500;
    final json = _meal(long).toJson();
    expect((json['name'] as String).length, Meal.maxNameLength);
  });

  test('الاسم القصير يبقى كما هو', () {
    expect(_meal('تمر').toJson()['name'], 'تمر');
  });

  test('fromJson يعكس toJson', () {
    final original = _meal('شاورما');
    final back = Meal.fromJson(original.toJson());
    expect(back.id, original.id);
    expect(back.name, original.name);
    expect(back.calories, original.calories);
    expect(back.macros.protein, original.macros.protein);
    expect(back.type, original.type);
    expect(back.time, original.time);
  });

  test('fromJson يتحمّل أرقاماً عشرية من Firestore', () {
    final back = Meal.fromJson({
      'id': 'a',
      'name': 'صنف',
      'calories': 250.7,
      'protein': 10.4,
      'carbs': 20.6,
      'fat': 5.2,
      'time': DateTime(2026, 5, 1).toIso8601String(),
      'type': 'snack',
    });
    expect(back.calories, 251);
    expect(back.macros.protein, 10);
    expect(back.macros.carbs, 21);
  });

  test('نوع وجبة مجهول يسقط على سناك بدل الانهيار', () {
    final back = Meal.fromJson({
      'id': 'a',
      'name': 'صنف',
      'calories': 100,
      'protein': 0,
      'carbs': 0,
      'fat': 0,
      'time': DateTime(2026, 5, 1).toIso8601String(),
      'type': 'نوع_غير_معروف',
    });
    expect(back.type, MealType.snack);
  });

  test('جمع الماكروز يجمع كل الحقول', () {
    const a = Macros(protein: 10, carbs: 20, fat: 5);
    const b = Macros(protein: 3, carbs: 7, fat: 2);
    final sum = a + b;
    expect(sum.protein, 13);
    expect(sum.carbs, 27);
    expect(sum.fat, 7);
  });
}
