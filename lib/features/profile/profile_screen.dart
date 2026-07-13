import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/motion.dart';
import '../../data/profile_controller.dart';
import '../../data/unit_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_profile.dart';
import '../../theme/app_theme.dart';
import '../analytics/analytics_screen.dart';
import '../analytics/monthly_calendar_screen.dart';
import '../assistant/form_analyzer_screen.dart';
import '../detraining/detraining_screen.dart';
import '../fitness/exercise_library_screen.dart';
import '../fitness/workout_programs_screen.dart';
import '../meal_plan/meal_plan_screen.dart';
import '../progress/progress_photos_screen.dart';
import '../settings/theme_switcher.dart';
import '../../services/notification_service.dart';
import '../streak/streak_screen.dart';
import '../weight/weight_screen.dart';
import 'body_fat_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    final profile = context.watch<ProfileController>().profile;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(children: [
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary)),
              Text(loc.profile,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: c.textPrimary)),
            ]),
            const SizedBox(height: 12),
            if (profile != null) _headerCard(context, c, loc, profile),
            const SizedBox(height: 16),

            // unit toggle
            const _UnitToggleRow(),
            const SizedBox(height: 10),

            // sections
            _sectionLabel(c, loc.isAr ? 'الإحصاء' : 'Stats'),
            _row(context, c, Icons.bar_chart_rounded, loc.isAr ? 'إحصائيات الأسبوع' : 'Weekly stats',
                () => Navigator.push(context, ZadPageRoute(page: const AnalyticsScreen()))),
            _row(context, c, Icons.calendar_month_rounded, loc.isAr ? 'تقويم التغذية' : 'Nutrition calendar',
                () => Navigator.push(context, ZadPageRoute(page: const MonthlyCalendarScreen()))),
            _row(context, c, Icons.local_fire_department_rounded, loc.isAr ? 'الستريك والرانك' : 'Streak & Rank',
                () => Navigator.push(context, ZadPageRoute(page: const StreakScreen()))),

            _sectionLabel(c, loc.isAr ? 'التدريب' : 'Training'),
            _row(context, c, Icons.fitness_center_rounded, loc.isAr ? 'مكتبة التمارين' : 'Exercise Library',
                () => Navigator.push(context, ZadPageRoute(page: const ExerciseLibraryScreen()))),
            _row(context, c, Icons.event_note_rounded, loc.isAr ? 'برامج التدريب' : 'Workout Programs',
                () => Navigator.push(context, ZadPageRoute(page: const WorkoutProgramsScreen()))),
            _row(context, c, Icons.psychology_outlined, loc.isAr ? 'محلّل الأداء (AI)' : 'Form Analyzer (AI)',
                () => Navigator.push(context, ZadPageRoute(page: const FormAnalyzerScreen()))),
            _row(context, c, Icons.restart_alt_rounded, loc.comebackTitle,
                () => Navigator.push(context, ZadPageRoute(page: const DetrainingScreen()))),

            _sectionLabel(c, loc.isAr ? 'التغذية' : 'Nutrition'),
            _row(context, c, Icons.calendar_view_week_rounded, loc.isAr ? 'خطة الوجبات' : 'Meal Plan',
                () => Navigator.push(context, ZadPageRoute(page: const MealPlanScreen()))),

            _sectionLabel(c, loc.isAr ? 'الجسم' : 'Body'),
            _row(context, c, Icons.monitor_weight_outlined, loc.weightTracking,
                () => Navigator.push(context, ZadPageRoute(page: const WeightScreen()))),
            _row(context, c, Icons.percent_rounded, loc.isAr ? 'نسبة الدهون' : 'Body Fat %',
                () => Navigator.push(context, ZadPageRoute(page: const BodyFatScreen()))),
            _row(context, c, Icons.photo_library_outlined, loc.isAr ? 'صور التقدم' : 'Progress Photos',
                () => Navigator.push(context, ZadPageRoute(page: const ProgressPhotosScreen()))),

            _sectionLabel(c, loc.isAr ? 'الأهداف' : 'Goals'),
            _row(context, c, Icons.flag_outlined, loc.editGoal, () => _editGoal(context, profile)),
            if (profile != null)
              _row(context, c, Icons.tune_rounded, loc.isAr ? 'توزيع الماكروز' : 'Macro split',
                  () => _macroSplit(context, profile)),

            _sectionLabel(c, loc.isAr ? 'التطبيق' : 'App'),
            _row(context, c, Icons.palette_outlined, '${loc.appearance} · ${loc.language}',
                () => showThemeSwitcher(context)),
            const _WaterReminderRow(),
            _row(context, c, Icons.info_outline_rounded, loc.about, () => _about(context, loc)),
          ],
        ),
      ),
    );
  }

  Widget _headerCard(BuildContext context, c, AppLocalizations loc, UserProfile p) {
    final initial = p.name.isNotEmpty ? p.name.characters.first : '?';
    return GestureDetector(
      onTap: () {
        Haptics.select();
        showModalBottomSheet(
          context: context,
          backgroundColor: c.surface,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          builder: (_) => _EditProfileSheet(profile: p),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: c.border)),
        child: Row(children: [
          Container(
            width: 56, height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.accent.withOpacity(0.15), shape: BoxShape.circle),
            child: Text(initial, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: c.accent)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: c.textPrimary)),
              const SizedBox(height: 4),
              Text('${loc.yourTarget}: ${p.targetCalories} ${loc.calorieUnit} · ${loc.bmiLabel} ${p.bmi.toStringAsFixed(1)}',
                  style: TextStyle(fontSize: 13, color: c.textSecondary)),
              const SizedBox(height: 4),
              Text(loc.isAr ? 'اضغط لتعديل ملفك' : 'Tap to edit profile',
                  style: TextStyle(fontSize: 11, color: c.textTertiary)),
            ]),
          ),
          Icon(Icons.edit_outlined, size: 18, color: c.textTertiary),
        ]),
      ),
    );
  }

  Widget _sectionLabel(c, String label) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.textTertiary)),
      );

  Widget _row(BuildContext context, c, IconData icon, String label, VoidCallback onTap) => GestureDetector(
        onTap: () {
          Haptics.select();
          onTap();
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.border)),
          child: Row(children: [
            Icon(icon, size: 22, color: c.accent),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: TextStyle(fontSize: 15, color: c.textPrimary))),
            Icon(Icons.chevron_right_rounded, color: c.textTertiary),
          ]),
        ),
      );

  void _macroSplit(BuildContext context, UserProfile profile) {
    final c = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _MacroSplitSheet(profile: profile),
    );
  }

  void _editGoal(BuildContext context, UserProfile? profile) {
    if (profile == null) return;
    final c = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _GoalSheet(profile: profile),
    );
  }

  void _about(BuildContext context, AppLocalizations loc) {
    showAboutDialog(
      context: context,
      applicationName: 'زاد',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2026',
    );
  }
}

// ─── Edit Profile Sheet ───────────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  final UserProfile profile;
  const _EditProfileSheet({required this.profile});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _name;
  late Gender _gender;
  late double _age, _height, _weight;
  late ActivityLevel _activity;
  late GoalType _goal;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _name = TextEditingController(text: p.name);
    _gender = p.gender;
    _age = p.age.toDouble();
    _height = p.heightCm.toDouble();
    _weight = p.weightKg;
    _activity = p.activity;
    _goal = p.goal;
  }

  @override
  void dispose() { _name.dispose(); super.dispose(); }

  UserProfile get _draft => UserProfile(
    name: _name.text.trim().isEmpty ? widget.profile.name : _name.text.trim(),
    gender: _gender, age: _age.round(), heightCm: _height.round(),
    weightKg: _weight, activity: _activity, goal: _goal,
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            decoration: BoxDecoration(color: c.textTertiary, borderRadius: BorderRadius.circular(4)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(children: [
              Text(loc.isAr ? 'تعديل الملف الشخصي' : 'Edit Profile',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: c.textPrimary)),
              const Spacer(),
              TextButton(
                onPressed: () {
                  if (_name.text.trim().isEmpty) return;
                  context.read<ProfileController>().save(_draft);
                  Haptics.light();
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  backgroundColor: c.accent, foregroundColor: c.onAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(loc.save, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                _label(c, loc.nameQ),
                TextField(
                  controller: _name,
                  style: TextStyle(color: c.textPrimary),
                  decoration: InputDecoration(
                    hintText: loc.namePlaceholder,
                    hintStyle: TextStyle(color: c.textTertiary),
                    filled: true, fillColor: c.surfaceVariant,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.accent)),
                  ),
                ),
                const SizedBox(height: 20),
                _label(c, loc.genderQ),
                Row(children: [
                  _chip(c, loc.male, _gender == Gender.male, () => setState(() => _gender = Gender.male)),
                  const SizedBox(width: 10),
                  _chip(c, loc.female, _gender == Gender.female, () => setState(() => _gender = Gender.female)),
                ]),
                const SizedBox(height: 20),
                _slider(c, '${loc.ageQ}: ${_age.round()}', _age, 15, 80, (v) => setState(() => _age = v)),
                _slider(c, '${loc.heightQ}: ${_height.round()} cm', _height, 140, 210, (v) => setState(() => _height = v)),
                _slider(c, '${loc.weightQ}: ${_weight.toStringAsFixed(1)} kg', _weight, 40, 160, (v) => setState(() => _weight = v)),
                const SizedBox(height: 16),
                _label(c, loc.activityQ),
                Wrap(spacing: 10, runSpacing: 10, children: [
                  for (final a in ActivityLevel.values)
                    _chip(c, loc.activityLabel(a), _activity == a, () => setState(() => _activity = a)),
                ]),
                const SizedBox(height: 20),
                _label(c, loc.goalQ),
                Wrap(spacing: 10, runSpacing: 10, children: [
                  for (final g in GoalType.values)
                    _chip(c, loc.goalLabel(g), _goal == g, () => setState(() => _goal = g)),
                ]),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: c.accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16), border: Border.all(color: c.accent.withOpacity(0.3))),
                  child: Row(children: [
                    Text(loc.yourTarget, style: TextStyle(fontSize: 14, color: c.textSecondary)),
                    const Spacer(),
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: widget.profile.targetCalories, end: _draft.targetCalories),
                      duration: const Duration(milliseconds: 300),
                      builder: (_, v, __) => Text('$v',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: c.accent)),
                    ),
                    const SizedBox(width: 4),
                    Text(loc.calorieUnit, style: TextStyle(fontSize: 13, color: c.textSecondary)),
                  ]),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _label(c, String t) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(t, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.textPrimary)));

  Widget _chip(c, String label, bool selected, VoidCallback onTap) => GestureDetector(
      onTap: () { Haptics.select(); onTap(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? c.accent.withOpacity(0.14) : c.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? c.accent : c.border, width: selected ? 2 : 1),
        ),
        child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
            color: selected ? c.accent : c.textPrimary)),
      ));

  Widget _slider(c, String label, double value, double min, double max, ValueChanged<double> onChanged) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.textPrimary)),
          Slider(value: value, min: min, max: max, activeColor: c.accent, inactiveColor: c.track, onChanged: onChanged),
        ]),
      );
}

// ─── Goal Sheet ───────────────────────────────────────────────────────────────

class _GoalSheet extends StatefulWidget {
  final UserProfile profile;
  const _GoalSheet({required this.profile});

  @override
  State<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends State<_GoalSheet> {
  late GoalType _goal = widget.profile.goal;
  late ActivityLevel _activity = widget.profile.activity;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    final preview = widget.profile.copyWith(goal: _goal, activity: _activity);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(color: c.textTertiary, borderRadius: BorderRadius.circular(4)),
            ),
          ),
          Text(loc.goalQ, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.textPrimary)),
          const SizedBox(height: 10),
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final g in GoalType.values) _chip(c, loc.goalLabel(g), _goal == g, () => setState(() => _goal = g)),
          ]),
          const SizedBox(height: 18),
          Text(loc.activityQ, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.textPrimary)),
          const SizedBox(height: 10),
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final a in ActivityLevel.values) _chip(c, loc.activityLabel(a), _activity == a, () => setState(() => _activity = a)),
          ]),
          const SizedBox(height: 18),
          Row(children: [
            Text(loc.yourTarget, style: TextStyle(fontSize: 14, color: c.textSecondary)),
            const Spacer(),
            Text('${preview.targetCalories} ${loc.calorieUnit}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.accent)),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                context.read<ProfileController>().save(preview);
                Haptics.light();
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                backgroundColor: c.accent,
                foregroundColor: c.onAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(loc.save, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _chip(c, String label, bool selected, VoidCallback onTap) => GestureDetector(
        onTap: () {
          Haptics.select();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? c.accent.withOpacity(0.14) : c.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? c.accent : c.border, width: selected ? 2 : 1),
          ),
          child: Text(label,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: selected ? c.accent : c.textPrimary)),
        ),
      );
}

// ─── Water Reminder Toggle Row ────────────────────────────────────────────────

class _WaterReminderRow extends StatefulWidget {
  const _WaterReminderRow();

  @override
  State<_WaterReminderRow> createState() => _WaterReminderRowState();
}

class _WaterReminderRowState extends State<_WaterReminderRow> {
  static const _prefsKey = 'zad_water_reminders_on';
  bool _on = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      if (mounted) setState(() => _on = prefs.getBool(_prefsKey) ?? false);
    });
  }

  Future<void> _toggle(bool value) async {
    final loc = AppLocalizations.of(context);
    final c = context.colors;
    if (value) {
      final granted = await NotificationService.requestPermissions();
      if (!mounted) return;
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(loc.isAr ? 'اسمح بالإشعارات من إعدادات الجهاز أولاً' : 'Allow notifications in device settings first'),
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }
      await NotificationService.scheduleWaterReminders();
    } else {
      await NotificationService.cancelWaterReminders();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
    if (!mounted) return;
    Haptics.select();
    setState(() => _on = value);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(value
          ? (loc.isAr ? 'فُعّلت تذكيرات الماء' : 'Water reminders on')
          : (loc.isAr ? 'أُوقفت تذكيرات الماء' : 'Water reminders off')),
      backgroundColor: c.surface,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.border)),
      child: Row(children: [
        Icon(Icons.notifications_outlined, size: 22, color: c.accent),
        const SizedBox(width: 14),
        Expanded(child: Text(loc.isAr ? 'تذكيرات الماء' : 'Water reminders',
            style: TextStyle(fontSize: 15, color: c.textPrimary))),
        Switch.adaptive(
          value: _on,
          onChanged: _toggle,
          activeColor: c.accent,
        ),
      ]),
    );
  }
}

// ─── Unit Toggle Row ──────────────────────────────────────────────────────────

class _UnitToggleRow extends StatelessWidget {
  const _UnitToggleRow();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    final unit = context.watch<UnitController>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Row(children: [
        Icon(Icons.straighten_rounded, size: 20, color: c.accent),
        const SizedBox(width: 12),
        Text(loc.unitToggle, style: TextStyle(fontSize: 15, color: c.textPrimary)),
        const Spacer(),
        GestureDetector(
          onTap: () { Haptics.select(); unit.toggle(); },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: c.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.border),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _pill(c, 'كجم', unit.useKg),
              const SizedBox(width: 4),
              _pill(c, 'lbs', !unit.useKg),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _pill(c, String label, bool active) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? c.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: active ? c.onAccent : c.textSecondary,
            )),
      );
}

// ─── Macro Split Sheet ────────────────────────────────────────────────────────

class _MacroSplitSheet extends StatefulWidget {
  final UserProfile profile;
  const _MacroSplitSheet({required this.profile});

  @override
  State<_MacroSplitSheet> createState() => _MacroSplitSheetState();
}

class _MacroSplitSheetState extends State<_MacroSplitSheet> {
  late double _proteinPct = 30;
  late double _carbsPct = 45;
  late double _fatPct = 25;

  int get _cal => widget.profile.targetCalories;
  int get _proteinG => (_cal * _proteinPct / 100 / 4).round();
  int get _carbsG => (_cal * _carbsPct / 100 / 4).round();
  int get _fatG => (_cal * _fatPct / 100 / 9).round();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(
            width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: c.textTertiary, borderRadius: BorderRadius.circular(4)),
          )),
          Text(loc.isAr ? 'توزيع الماكروز' : 'Macro split',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: c.textPrimary)),
          const SizedBox(height: 20),
          _macroSlider(c, loc.protein, _proteinPct, c.macroProtein, _proteinG, 'g',
              (v) => setState(() { _proteinPct = v; _fatPct = (100 - v - _carbsPct).clamp(5, 80); })),
          _macroSlider(c, loc.carbs, _carbsPct, c.macroCarbs, _carbsG, 'g',
              (v) => setState(() { _carbsPct = v; _fatPct = (100 - _proteinPct - v).clamp(5, 80); })),
          _macroSlider(c, loc.fat, _fatPct, c.macroFat, _fatG, 'g', null),
          const SizedBox(height: 4),
          Text('${(_proteinPct + _carbsPct + _fatPct).round()}% total',
              style: TextStyle(fontSize: 11, color: c.textTertiary)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () { Haptics.light(); Navigator.pop(context); },
              style: TextButton.styleFrom(
                backgroundColor: c.accent, foregroundColor: c.onAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(loc.save, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _macroSlider(c, String label, double val, Color color, int grams, String unit, ValueChanged<double>? onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.textPrimary)),
        const Spacer(),
        Text('${val.round()}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(width: 8),
        Text('$grams$unit', style: TextStyle(fontSize: 12, color: c.textSecondary)),
      ]),
      Slider(
        value: val, min: 5, max: 75,
        activeColor: color, inactiveColor: c.track,
        onChanged: onChanged,
      ),
    ]);
  }
}
