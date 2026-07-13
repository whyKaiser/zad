import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/motion.dart';
import '../../data/diary_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/meal.dart';
import '../../theme/app_theme.dart';

class CustomFoodScreen extends StatefulWidget {
  final MealType defaultType;
  const CustomFoodScreen({super.key, this.defaultType = MealType.snack});

  @override
  State<CustomFoodScreen> createState() => _CustomFoodScreenState();
}

class _CustomFoodScreenState extends State<CustomFoodScreen> {
  final _name = TextEditingController();
  final _cal = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  late MealType _type;

  @override
  void initState() {
    super.initState();
    _type = widget.defaultType;
  }

  @override
  void dispose() {
    _name.dispose();
    _cal.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    super.dispose();
  }

  bool get _valid =>
      _name.text.trim().isNotEmpty && int.tryParse(_cal.text) != null;

  void _save() {
    if (!_valid) return;
    final repo = context.read<DiaryRepository>();
    repo.addMeal(Meal(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: _name.text.trim(),
      calories: int.parse(_cal.text),
      macros: Macros(
        protein: int.tryParse(_protein.text) ?? 0,
        carbs: int.tryParse(_carbs.text) ?? 0,
        fat: int.tryParse(_fat.text) ?? 0,
      ),
      time: DateTime.now(),
      type: _type,
    ));
    Haptics.light();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(
                  loc.isAr ? 'طعام مخصص' : 'Custom food',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: c.textPrimary),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: c.textSecondary),
                ),
              ]),
              const SizedBox(height: 16),

              // meal type
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: MealType.values.map((t) {
                    final sel = t == _type;
                    return GestureDetector(
                      onTap: () { Haptics.select(); setState(() => _type = t); },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? c.accent.withOpacity(0.14) : c.surfaceVariant,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: sel ? c.accent : c.border, width: sel ? 1.5 : 1),
                        ),
                        child: Text(loc.mealTypeLabel(t),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                                color: sel ? c.accent : c.textSecondary)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              _Field(
                controller: _name,
                label: loc.isAr ? 'اسم الطعام' : 'Food name',
                hint: loc.isAr ? 'مثل: شاورما خاصة' : 'e.g. Home burger',
                c: c,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              _Field(
                controller: _cal,
                label: loc.isAr ? 'السعرات (kcal)' : 'Calories (kcal)',
                hint: '0',
                c: c,
                numeric: true,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),
              Text(
                loc.isAr ? 'الماكروز (اختياري)' : 'Macros (optional)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textSecondary),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _Field(controller: _protein, label: loc.protein, hint: '0', c: c, numeric: true)),
                const SizedBox(width: 12),
                Expanded(child: _Field(controller: _carbs, label: loc.carbs, hint: '0', c: c, numeric: true)),
                const SizedBox(width: 12),
                Expanded(child: _Field(controller: _fat, label: loc.fat, hint: '0', c: c, numeric: true)),
              ]),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: AnimatedOpacity(
                  opacity: _valid ? 1 : 0.4,
                  duration: const Duration(milliseconds: 200),
                  child: TextButton(
                    onPressed: _valid ? _save : null,
                    style: TextButton.styleFrom(
                      backgroundColor: c.accent,
                      foregroundColor: c.onAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      loc.isAr ? 'أضف إلى ${loc.mealTypeLabel(_type)}' : 'Add to ${loc.mealTypeLabel(_type)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final dynamic c;
  final bool numeric;
  final ValueChanged<String>? onChanged;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.c,
    this.numeric = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: c.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: numeric ? TextInputType.number : TextInputType.text,
          inputFormatters: numeric ? [FilteringTextInputFormatter.digitsOnly] : null,
          style: TextStyle(color: c.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: c.textTertiary),
            filled: true,
            fillColor: c.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.accent)),
          ),
        ),
      ],
    );
  }
}
