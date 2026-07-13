import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/motion.dart';
import '../../data/diary_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/meal.dart';
import '../../services/food_lookup.dart';
import '../../theme/app_theme.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _Entry {
  final String query;
  FoodResult? result;
  bool loading = true;
  bool error = false;
  bool added = false;
  _Entry(this.query);
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<_Entry> _entries = [];

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    Haptics.light();
    _controller.clear();

    final entry = _Entry(text);
    setState(() => _entries.add(entry));
    _scrollToEnd();

    try {
      final result = await context.read<FoodLookup>().estimate(text);
      setState(() {
        entry.result = result;
        entry.loading = false;
      });
    } catch (_) {
      setState(() {
        entry.loading = false;
        entry.error = true;
      });
    }
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  /// يستنتج نوع الوجبة من وقت اليوم.
  MealType _inferType() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 11) return MealType.breakfast;
    if (h >= 11 && h < 16) return MealType.lunch;
    if (h >= 16 && h < 22) return MealType.dinner;
    return MealType.snack;
  }

  void _addToDiary(_Entry entry) {
    final r = entry.result!;
    context.read<DiaryRepository>().addMeal(Meal(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: r.name,
          calories: r.calories,
          macros: r.macros,
          time: DateTime.now(),
          type: _inferType(),
        ));
    Haptics.light();
    setState(() => entry.added = true);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: _entries.isEmpty
                ? _EmptyState(text: loc.assistantEmpty)
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: _entries.length,
                    itemBuilder: (_, i) => _EntryView(
                      entry: _entries[i],
                      onAdd: () => _addToDiary(_entries[i]),
                    ),
                  ),
          ),
          _InputBar(controller: _controller, hint: loc.assistantHint, onSend: _submit),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 40, color: c.accent),
          const SizedBox(height: 14),
          Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: c.textSecondary)),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }
}

class _EntryView extends StatelessWidget {
  final _Entry entry;
  final VoidCallback onAdd;
  const _EntryView({required this.entry, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // فقاعة المستخدم
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: c.accent,
                borderRadius: const BorderRadius.all(Radius.circular(16)),
              ),
              child: Text(entry.query,
                  style: TextStyle(color: c.onAccent, fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          ),
          const SizedBox(height: 10),
          if (entry.loading)
            Row(children: [
              SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: c.accent)),
              const SizedBox(width: 10),
              Text(loc.thinking, style: TextStyle(color: c.textSecondary, fontSize: 14)),
            ])
          else if (entry.error)
            Text(loc.tryAgain, style: TextStyle(color: c.macroFat, fontSize: 14))
          else if (entry.result != null)
            _ResultCard(result: entry.result!, added: entry.added, onAdd: onAdd)
                .animate().fadeIn(duration: 350.ms).slideY(begin: 0.1, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final FoodResult result;
  final bool added;
  final VoidCallback onAdd;
  const _ResultCard({required this.result, required this.added, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    final approx = result.isApproximate;
    final badgeColor = approx ? c.macroCarbs : c.accent2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(result.name,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: c.textPrimary)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(approx ? loc.approximate : loc.verified,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: badgeColor)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${result.calories}',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: c.accent)),
              const SizedBox(width: 4),
              Text(loc.calorieUnit, style: TextStyle(fontSize: 13, color: c.textSecondary)),
            ],
          ),
          const SizedBox(height: 10),
          Row(children: [
            _macro(c, '${loc.protein} ${result.macros.protein}', c.macroProtein),
            const SizedBox(width: 8),
            _macro(c, '${loc.carbs} ${result.macros.carbs}', c.macroCarbs),
            const SizedBox(width: 8),
            _macro(c, '${loc.fat} ${result.macros.fat}', c.macroFat),
          ]),
          if (result.detail.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(result.detail,
                style: TextStyle(fontSize: 11, color: c.textTertiary), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: added ? null : onAdd,
              style: TextButton.styleFrom(
                backgroundColor: added ? c.surfaceVariant : c.accent,
                foregroundColor: added ? c.textSecondary : c.onAccent,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(added ? loc.added : loc.addToDiary,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _macro(c, String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(7)),
        child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
      );
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onSend;
  const _InputBar({required this.controller, required this.hint, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: c.background,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: (_) => onSend(),
              textInputAction: TextInputAction.send,
              style: TextStyle(color: c.textPrimary),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: c.textTertiary, fontSize: 14),
                filled: true,
                fillColor: c.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: c.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: c.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: c.accent)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 46, height: 46,
              decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
              child: Icon(Icons.arrow_upward_rounded, color: c.onAccent),
            ),
          ),
        ],
      ),
    );
  }
}
