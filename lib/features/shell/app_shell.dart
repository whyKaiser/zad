import 'package:flutter/material.dart';

import '../../core/motion.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../add_meal/add_meal_screen.dart';
import '../analytics/analytics_screen.dart';
import '../assistant/assistant_screen.dart';
import '../challenges/challenges_screen.dart';
import '../home/home_screen.dart';
import '../restaurants/restaurants_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _icons = [
    Icons.home_rounded,
    Icons.bar_chart_rounded,
    Icons.auto_awesome_rounded,
    Icons.place_rounded,
    Icons.emoji_events_rounded,
  ];

  String _label(AppLocalizations loc, int i) => switch (i) {
        0 => loc.tabHome,
        1 => loc.tabAnalytics,
        2 => loc.tabAssistant,
        3 => loc.tabMap,
        _ => loc.tabChallenges,
      };

  Widget _screenFor(int i) => switch (i) {
        0 => const HomeScreen(),
        1 => const AnalyticsScreen(),
        2 => const AssistantScreen(),
        3 => const RestaurantsScreen(),
        _ => const ChallengesScreen(),
      };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutCubic,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.02), end: Offset.zero).animate(anim),
            child: child,
          ),
        ),
        child: KeyedSubtree(key: ValueKey(_index), child: _screenFor(_index)),
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton(
              backgroundColor: c.accent,
              foregroundColor: c.onAccent,
              elevation: 0,
              onPressed: () {
                Haptics.light();
                Navigator.push(context, ZadPageRoute(page: const AddMealScreen()));
              },
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: List.generate(_icons.length, (i) {
                final selected = i == _index;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (i == _index) return;
                      Haptics.select();
                      setState(() => _index = i);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedScale(
                          scale: selected ? 1.15 : 1,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutBack,
                          child: Icon(
                            _icons[i],
                            size: 24,
                            color: selected ? c.accent : c.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 250),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            color: selected ? c.accent : c.textTertiary,
                          ),
                          child: Text(_label(loc, i)),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
