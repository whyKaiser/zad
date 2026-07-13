import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../data/exercise_data.dart';
import '../../l10n/app_localizations.dart';
import '../../models/exercise.dart';
import '../../theme/app_theme.dart';

class _Program {
  final String nameAr;
  final String nameEn;
  final String descAr;
  final String descEn;
  final List<_WorkoutDay> days;
  const _Program({required this.nameAr, required this.nameEn, required this.descAr, required this.descEn, required this.days});
}

class _WorkoutDay {
  final String nameAr;
  final String nameEn;
  final List<String> exerciseIds;
  const _WorkoutDay({required this.nameAr, required this.nameEn, required this.exerciseIds});
}

const _programs = [
  _Program(
    nameAr: 'مبتدئ — جسم كامل',
    nameEn: 'Beginner Full Body',
    descAr: '3 أيام أسبوعياً، تمارين أساسية',
    descEn: '3 days/week, compound movements',
    days: [
      _WorkoutDay(nameAr: 'يوم أ', nameEn: 'Day A', exerciseIds: ['squat', 'bench_press', 'lat_pulldown', 'plank']),
      _WorkoutDay(nameAr: 'يوم ب', nameEn: 'Day B', exerciseIds: ['squat', 'ohp', 'seated_row', 'crunch']),
      _WorkoutDay(nameAr: 'يوم ج', nameEn: 'Day C', exerciseIds: ['lunge', 'incline_press', 'pullup', 'plank']),
    ],
  ),
  _Program(
    nameAr: 'تقسيم الدفع/الشد',
    nameEn: 'Push/Pull Split',
    descAr: '4 أيام أسبوعياً، تقسيم عضلي',
    descEn: '4 days/week, muscle split',
    days: [
      _WorkoutDay(nameAr: 'دفع', nameEn: 'Push', exerciseIds: ['bench_press', 'ohp', 'incline_press', 'lateral_raise', 'tricep_dip']),
      _WorkoutDay(nameAr: 'شد', nameEn: 'Pull', exerciseIds: ['pullup', 'lat_pulldown', 'seated_row', 'bicep_curl']),
      _WorkoutDay(nameAr: 'أرجل', nameEn: 'Legs', exerciseIds: ['squat', 'lunge', 'leg_press', 'calf_raise']),
      _WorkoutDay(nameAr: 'كارديو + كور', nameEn: 'Cardio + Core', exerciseIds: ['running', 'burpee', 'plank', 'crunch']),
    ],
  ),
  _Program(
    nameAr: 'إنقاص الوزن',
    nameEn: 'Fat Loss',
    descAr: '5 أيام، تمارين حرق + مقاومة',
    descEn: '5 days, HIIT + resistance',
    days: [
      _WorkoutDay(nameAr: 'الاثنين', nameEn: 'Mon', exerciseIds: ['burpee', 'squat', 'pushup', 'jump_rope']),
      _WorkoutDay(nameAr: 'الثلاثاء', nameEn: 'Tue', exerciseIds: ['running', 'lunge', 'plank', 'crunch']),
      _WorkoutDay(nameAr: 'الأربعاء', nameEn: 'Wed', exerciseIds: ['bench_press', 'lat_pulldown', 'ohp', 'tricep_dip']),
      _WorkoutDay(nameAr: 'الخميس', nameEn: 'Thu', exerciseIds: ['burpee', 'jump_rope', 'squat', 'plank']),
      _WorkoutDay(nameAr: 'الجمعة', nameEn: 'Fri', exerciseIds: ['running', 'pullup', 'bicep_curl', 'calf_raise']),
    ],
  ),
];

class WorkoutProgramsScreen extends StatefulWidget {
  const WorkoutProgramsScreen({super.key});

  @override
  State<WorkoutProgramsScreen> createState() => _WorkoutProgramsScreenState();
}

class _WorkoutProgramsScreenState extends State<WorkoutProgramsScreen> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    final prog = _programs[_selected];

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(children: [
                IconButton(onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary)),
                Text(loc.isAr ? 'برامج التدريب' : 'Workout Programs',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: c.textPrimary)),
              ]),
            ),
            // program selector
            SizedBox(
              height: 44,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _programs.length,
                itemBuilder: (_, i) {
                  final sel = i == _selected;
                  return GestureDetector(
                    onTap: () => setState(() => _selected = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? c.accent.withOpacity(0.14) : c.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sel ? c.accent : c.border, width: sel ? 1.5 : 1),
                      ),
                      child: Text(loc.isAr ? _programs[i].nameAr : _programs[i].nameEn,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                              color: sel ? c.accent : c.textSecondary)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.border)),
                child: Text(loc.isAr ? prog.descAr : prog.descEn,
                    style: TextStyle(fontSize: 13, color: c.textSecondary)),
              ),
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                itemCount: prog.days.length,
                itemBuilder: (_, di) {
                  final day = prog.days[di];
                  final exercises = day.exerciseIds.map(exerciseById).whereType<Exercise>().toList();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: c.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border),
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: Text(loc.isAr ? day.nameAr : day.nameEn,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.textPrimary)),
                      subtitle: Text('${exercises.length} ${loc.isAr ? "تمرين" : "exercises"}',
                          style: TextStyle(fontSize: 12, color: c.textSecondary)),
                      iconColor: c.accent,
                      collapsedIconColor: c.textTertiary,
                      children: exercises.map((ex) => ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        leading: Text(ex.muscle.emoji, style: const TextStyle(fontSize: 20)),
                        title: Text(loc.isAr ? ex.nameAr : ex.nameEn,
                            style: TextStyle(fontSize: 14, color: c.textPrimary)),
                        trailing: Text('${ex.sets}×${ex.reps}',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.accent)),
                      )).toList(),
                    ),
                  ).animate().fadeIn(delay: (di * 80).ms);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
