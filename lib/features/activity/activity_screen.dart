import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';

import '../../core/motion.dart';
import '../../data/activity_controller.dart';
import '../../data/profile_controller.dart';
import '../../data/weight_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// تسجيل النشاط — السعرات المحروقة تُضاف لميزانية اليوم.
class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    final ctrl = context.watch<ActivityController>();
    final today = ctrl.forDay(DateTime.now())..sort((a, b) => b.date.compareTo(a.date));
    final burned = ctrl.burnedToday;

    return Scaffold(
      backgroundColor: c.background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        elevation: 0,
        onPressed: () => _openAdd(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(loc.isAr ? 'سجّل نشاط' : 'Log activity',
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(children: [
                IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary),
                ),
                Text(loc.isAr ? 'النشاط والحركة' : 'Activity',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: c.textPrimary)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: c.border),
                ),
                child: Column(children: [
                  Icon(Icons.local_fire_department_rounded, size: 34, color: c.accent2),
                  const SizedBox(height: 6),
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: burned),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => Text('$v',
                        style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800,
                            color: c.textPrimary, height: 1)),
                  ),
                  Text(loc.isAr ? 'سعرة محروقة اليوم' : 'calories burned today',
                      style: TextStyle(fontSize: 14, color: c.textSecondary)),
                  if (burned > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: c.accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        loc.isAr ? '+$burned سعرة أُضيفت لميزانيتك' : '+$burned added to your budget',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.accent),
                      ),
                    ),
                  ],
                ]),
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.12, curve: Curves.easeOutCubic),
            const SizedBox(height: 16),
            Expanded(
              child: today.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.directions_run_rounded, size: 40, color: c.textTertiary),
                          const SizedBox(height: 12),
                          Text(
                            loc.isAr
                                ? 'ما سجّلت نشاط اليوم.\nكل حركة تزيد ميزانية سعراتك.'
                                : 'No activity logged today.\nEvery move adds to your budget.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, height: 1.6, color: c.textSecondary),
                          ),
                        ]),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: today.length,
                      itemBuilder: (_, i) {
                        final e = today[i];
                        final type = activityById(e.id);
                        return Dismissible(
                          key: ValueKey('${e.id}_${e.date.toIso8601String()}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: AlignmentDirectional.centerEnd,
                            padding: const EdgeInsetsDirectional.only(end: 20),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: c.danger,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
                          ),
                          onDismissed: (_) {
                            Haptics.light();
                            context.read<ActivityController>().remove(e);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: c.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: c.border),
                            ),
                            child: Row(children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: c.accent.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(type?.icon ?? Icons.fitness_center_rounded,
                                    size: 20, color: c.accent),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(e.name,
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                          color: c.textPrimary)),
                                  Text(
                                    '${e.minutes} ${loc.isAr ? "دقيقة" : "min"} · ${intl.DateFormat('h:mm a').format(e.date)}',
                                    style: TextStyle(fontSize: 12, color: c.textSecondary),
                                  ),
                                ]),
                              ),
                              Text('${e.calories}',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.accent2)),
                              Text(' ${loc.calorieUnit}',
                                  style: TextStyle(fontSize: 10, color: c.textTertiary)),
                            ]),
                          ),
                        ).animate().fadeIn(delay: (i * 22).ms, duration: 300.ms);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAdd(BuildContext context) {
    Haptics.select();
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _AddActivitySheet(),
    );
  }
}

class _AddActivitySheet extends StatefulWidget {
  const _AddActivitySheet();

  @override
  State<_AddActivitySheet> createState() => _AddActivitySheetState();
}

class _AddActivitySheetState extends State<_AddActivitySheet> {
  ActivityType _type = kActivities.first;
  double _minutes = 30;

  /// وزن المستخدم: آخر تسجيل وزن، وإلا وزن الملف، وإلا افتراضي معقول.
  double _weight(BuildContext context) =>
      context.read<WeightController>().latest ??
      context.read<ProfileController>().profile?.weightKg ??
      70;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    final weight = _weight(context);
    final cals = _type.caloriesFor(weightKg: weight, minutes: _minutes.round());

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) => Column(children: [
        Container(
          width: 40, height: 4,
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: c.textTertiary, borderRadius: BorderRadius.circular(4)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Text(loc.isAr ? 'سجّل نشاط' : 'Log activity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: c.textPrimary)),
            const Spacer(),
            Text('$cals ${loc.calorieUnit}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: c.accent2)),
          ]),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final a in kActivities)
                  ZadTap(
                    onTap: () { Haptics.select(); setState(() => _type = a); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: _type.id == a.id ? c.accent.withOpacity(0.14) : c.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _type.id == a.id ? c.accent : c.border,
                          width: _type.id == a.id ? 1.6 : 1,
                        ),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(a.icon, size: 16,
                            color: _type.id == a.id ? c.accent : c.textSecondary),
                        const SizedBox(width: 6),
                        Text(loc.isAr ? a.nameAr : a.nameEn,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                                color: _type.id == a.id ? c.accent : c.textPrimary)),
                      ]),
                    ),
                  ),
              ]),
              const SizedBox(height: 22),
              Row(children: [
                Text(loc.isAr ? 'المدة' : 'Duration',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.textPrimary)),
                const Spacer(),
                Text('${_minutes.round()} ${loc.isAr ? "دقيقة" : "min"}',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.accent)),
              ]),
              Slider(
                value: _minutes, min: 5, max: 180, divisions: 35,
                activeColor: c.accent, inactiveColor: c.track,
                onChanged: (v) => setState(() => _minutes = v),
              ),
              const SizedBox(height: 4),
              Text(
                loc.isAr
                    ? 'محسوبة على وزن ${weight.toStringAsFixed(0)} كجم بمعادلة MET المعتمدة.'
                    : 'Calculated for ${weight.toStringAsFixed(0)} kg using standard MET values.',
                style: TextStyle(fontSize: 11, height: 1.5, color: c.textTertiary),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    context.read<ActivityController>().add(ActivityEntry(
                          id: _type.id,
                          name: loc.isAr ? _type.nameAr : _type.nameEn,
                          minutes: _minutes.round(),
                          calories: cals,
                          date: DateTime.now(),
                        ));
                    Haptics.light();
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: c.accent, foregroundColor: c.onAccent,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(loc.save,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}
