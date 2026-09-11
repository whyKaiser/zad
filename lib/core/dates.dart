/// أدوات التاريخ المشتركة. وُحّدت هنا لأن تكرار منطق "نفس اليوم"
/// في عدة ملفات كان مصدر أخطاء (تسجيل في اليوم الخطأ، ستريك مزاح بيوم).
library;

/// هل التاريخان في اليوم نفسه (بتجاهل الوقت)؟
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// هل التاريخ هو اليوم الحالي؟
bool isToday(DateTime d) => isSameDay(d, DateTime.now());

/// مفتاح تخزين اليوم — `2026-09-11`. مستعمل في Firestore والتخزين المحلي.
String dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// وقت تسجيل وجبة في يوم معيّن: تاريخ اليوم المعروض + ساعة الآن.
/// يمنع أن تحمل وجبةٌ سُجّلت ليوم سابق طابعَ وقتٍ من اليوم الحالي.
DateTime mealTimeFor(DateTime selectedDay) {
  final now = DateTime.now();
  if (isSameDay(selectedDay, now)) return now;
  return DateTime(
    selectedDay.year,
    selectedDay.month,
    selectedDay.day,
    now.hour,
    now.minute,
    now.second,
    now.millisecond,
  );
}
