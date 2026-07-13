import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../data/exercise_data.dart';
import '../../l10n/app_localizations.dart';
import '../../models/exercise.dart';
import '../../theme/app_theme.dart';

class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  MuscleGroup? _filter;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    final filtered = _filter == null ? kExercises : exercisesByMuscle(_filter!);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary),
                ),
                Text(loc.isAr ? 'مكتبة التمارين' : 'Exercise Library',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: c.textPrimary)),
              ]),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                children: [
                  _Chip(label: loc.isAr ? 'الكل' : 'All', selected: _filter == null,
                      onTap: () => setState(() => _filter = null)),
                  ...MuscleGroup.values.map((g) => _Chip(
                    label: loc.isAr ? g.nameAr : g.nameEn,
                    selected: _filter == g,
                    onTap: () => setState(() => _filter = g),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                itemCount: filtered.length,
                itemBuilder: (context, i) => _ExCard(ex: filtered[i], loc: loc)
                    .animate().fadeIn(delay: (i * 40).ms, duration: 300.ms),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? c.accent.withOpacity(0.14) : c.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? c.accent : c.border, width: selected ? 1.5 : 1),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
            color: selected ? c.accent : c.textSecondary)),
      ),
    );
  }
}

class _ExCard extends StatelessWidget {
  final Exercise ex;
  final AppLocalizations loc;
  const _ExCard({required this.ex, required this.loc});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: c.accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Text(ex.muscle.emoji, style: const TextStyle(fontSize: 22))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(loc.isAr ? ex.nameAr : ex.nameEn,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.textPrimary)),
          const SizedBox(height: 3),
          Text(loc.isAr ? ex.muscle.nameAr : ex.muscle.nameEn,
              style: TextStyle(fontSize: 12, color: c.accent)),
          const SizedBox(height: 4),
          Text(loc.isAr ? ex.descAr : ex.descEn,
              style: TextStyle(fontSize: 12, color: c.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
        ])),
        const SizedBox(width: 8),
        Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('${ex.sets}×${ex.reps}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.accent)),
          Text(loc.isAr ? 'ج×ت' : 'S×R',
              style: TextStyle(fontSize: 10, color: c.textTertiary)),
        ]),
      ]),
    );
  }
}
