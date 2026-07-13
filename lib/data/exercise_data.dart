import '../models/exercise.dart';

const List<Exercise> kExercises = [
  // صدر
  Exercise(id: 'bench_press', nameAr: 'بنش برس', nameEn: 'Bench Press', muscle: MuscleGroup.chest,
    descAr: 'استلقِ على مقعد مستوٍ، أمسك البار بعرض الكتفين، انزل حتى يلمس الصدر ثم ارفع.', descEn: 'Lie on flat bench, grip bar shoulder-width, lower to chest, press up.', sets: 4, reps: 10),
  Exercise(id: 'pushup', nameAr: 'ضغط أرضي', nameEn: 'Push-up', muscle: MuscleGroup.chest,
    descAr: 'ضع يديك بعرض الكتفين، جسمك مستقيم، انزل حتى تلامس صدرك الأرض ثم ارتفع.', descEn: 'Hands shoulder-width, body straight, lower chest to floor, push up.', sets: 3, reps: 15),
  Exercise(id: 'incline_press', nameAr: 'بنش مائل', nameEn: 'Incline Press', muscle: MuscleGroup.chest,
    descAr: 'مقعد بزاوية 30-45 درجة، يركز على الجزء العلوي من الصدر.', descEn: '30-45° incline bench targets upper chest.', sets: 3, reps: 12),

  // ظهر
  Exercise(id: 'pullup', nameAr: 'بول أب', nameEn: 'Pull-up', muscle: MuscleGroup.back,
    descAr: 'أمسك البار، اسحب جسمك حتى يصل ذقنك فوق البار.', descEn: 'Hang from bar, pull until chin clears bar.', sets: 3, reps: 8),
  Exercise(id: 'lat_pulldown', nameAr: 'لات بول داون', nameEn: 'Lat Pulldown', muscle: MuscleGroup.back,
    descAr: 'اسحب البار نحو صدرك مع تقوس خفيف للظهر للخلف.', descEn: 'Pull bar to chest with slight back arch.', sets: 4, reps: 12),
  Exercise(id: 'seated_row', nameAr: 'روينج جلوس', nameEn: 'Seated Row', muscle: MuscleGroup.back,
    descAr: 'اسحب المقبض نحو بطنك مع ثبات الجذع.', descEn: 'Pull handle toward abdomen, keep torso still.', sets: 3, reps: 12),

  // أكتاف
  Exercise(id: 'ohp', nameAr: 'ضغط فوق الرأس', nameEn: 'Overhead Press', muscle: MuscleGroup.shoulders,
    descAr: 'ارفع البار من مستوى الصدر حتى فوق الرأس مع تثبيت الجذع.', descEn: 'Press bar from chest level overhead, brace core.', sets: 4, reps: 10),
  Exercise(id: 'lateral_raise', nameAr: 'رفع جانبي', nameEn: 'Lateral Raise', muscle: MuscleGroup.shoulders,
    descAr: 'ارفع الدمبل للجانبين حتى مستوى الأكتاف مع طي خفيف بالمرفق.', descEn: 'Raise dumbbells to sides at shoulder height, slight elbow bend.', sets: 3, reps: 15),

  // أذرع
  Exercise(id: 'bicep_curl', nameAr: 'كيرل بايسبس', nameEn: 'Bicep Curl', muscle: MuscleGroup.arms,
    descAr: 'اثنِ المرفق لرفع الدمبل نحو الكتف دون تحريك الكتف.', descEn: 'Curl dumbbell toward shoulder without swinging.', sets: 3, reps: 12),
  Exercise(id: 'tricep_dip', nameAr: 'تراي ديبس', nameEn: 'Tricep Dip', muscle: MuscleGroup.arms,
    descAr: 'على مقعد، انزل بجسمك حتى يصبح المرفق بزاوية 90 درجة ثم ارتفع.', descEn: 'Lower body until elbows 90°, press back up.', sets: 3, reps: 12),

  // أرجل
  Exercise(id: 'squat', nameAr: 'سكوات', nameEn: 'Squat', muscle: MuscleGroup.legs,
    descAr: 'قدماك بعرض الكتفين، انزل حتى تصبح فخذاك موازيين للأرض مع ثبات الظهر.', descEn: 'Feet shoulder-width, lower until thighs parallel, keep back straight.', sets: 4, reps: 10),
  Exercise(id: 'lunge', nameAr: 'لانج', nameEn: 'Lunge', muscle: MuscleGroup.legs,
    descAr: 'خطوة للأمام وانزل حتى يصبح الركبة الأمامية بزاوية 90 درجة.', descEn: 'Step forward, lower until front knee 90°.', sets: 3, reps: 12),
  Exercise(id: 'leg_press', nameAr: 'لق برس', nameEn: 'Leg Press', muscle: MuscleGroup.legs,
    descAr: 'ادفع المنصة لأعلى حتى يمتد الساق دون قفل الركبة.', descEn: 'Press platform until legs extended, avoid locking knees.', sets: 4, reps: 12),
  Exercise(id: 'calf_raise', nameAr: 'كالف رايز', nameEn: 'Calf Raise', muscle: MuscleGroup.legs,
    descAr: 'ارتفع على أطراف أصابع قدميك ببطء ثم انزل ببطء.', descEn: 'Rise on toes slowly, lower slowly.', sets: 4, reps: 20),

  // كور
  Exercise(id: 'plank', nameAr: 'بلانك', nameEn: 'Plank', muscle: MuscleGroup.core,
    descAr: 'جسمك مستقيم على المرفقين، حافظ على الوضع لمدة 30-60 ثانية.', descEn: 'Straight body on forearms, hold 30-60 seconds.', sets: 3, reps: 1),
  Exercise(id: 'crunch', nameAr: 'كرنش', nameEn: 'Crunch', muscle: MuscleGroup.core,
    descAr: 'استلقِ، اثنِ الركبتين، ارفع كتفيك عن الأرض مع ضغط البطن.', descEn: 'Lie back, knees bent, raise shoulders off floor, squeeze abs.', sets: 3, reps: 20),

  // كارديو
  Exercise(id: 'running', nameAr: 'جري', nameEn: 'Running', muscle: MuscleGroup.cardio,
    descAr: 'جري خفيف 20-30 دقيقة بسرعة ثابتة.', descEn: 'Light jog 20-30 min at steady pace.', sets: 1, reps: 1),
  Exercise(id: 'jump_rope', nameAr: 'حبل قفز', nameEn: 'Jump Rope', muscle: MuscleGroup.cardio,
    descAr: 'قفز بالحبل 3 جولات كل جولة دقيقتين مع استراحة دقيقة.', descEn: '3 rounds of 2 min jumping, 1 min rest.', sets: 3, reps: 1),
  Exercise(id: 'burpee', nameAr: 'بيربي', nameEn: 'Burpee', muscle: MuscleGroup.fullBody,
    descAr: 'انزل للضغط ثم قفز للأعلى بشكل متواصل.', descEn: 'Drop to push-up position then jump up, continuous.', sets: 3, reps: 10),
];

List<Exercise> exercisesByMuscle(MuscleGroup group) =>
    kExercises.where((e) => e.muscle == group).toList();

Exercise? exerciseById(String id) =>
    kExercises.where((e) => e.id == id).firstOrNull;
