import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../data/diary_repository.dart';
import '../../data/food_seed.dart';
import '../../data/profile_controller.dart';
import '../../data/restaurants_data.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class RestaurantsScreen extends StatelessWidget {
  const RestaurantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = AppLocalizations.of(context);
    final repo = context.watch<DiaryRepository>();
    final profile = context.watch<ProfileController>().profile;
    final goal = profile?.targetCalories ?? repo.goal.calories;
    final remaining = (goal - repo.consumedCalories).clamp(0, goal);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          Text(loc.nearbyRestaurants,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: c.textPrimary))
              .animate().fadeIn(duration: 350.ms),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.border),
            ),
            child: Row(children: [
              Icon(Icons.bolt_rounded, color: c.accent2, size: 20),
              const SizedBox(width: 10),
              Text(loc.remainingToday, style: TextStyle(fontSize: 14, color: c.textSecondary)),
              const Spacer(),
              Text('$remaining', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: c.accent)),
              const SizedBox(width: 4),
              Text(loc.calorieUnit, style: TextStyle(fontSize: 12, color: c.textSecondary)),
            ]),
          ).animate().fadeIn(delay: 80.ms),
          const SizedBox(height: 18),
          ...List.generate(kNearbyRestaurants.length, (i) {
            return _RestaurantCard(restaurant: kNearbyRestaurants[i], remaining: remaining, loc: loc)
                .animate()
                .fadeIn(delay: (150 + i * 80).ms, duration: 350.ms)
                .slideY(begin: 0.1, curve: Curves.easeOutCubic);
          }),
          const SizedBox(height: 8),
          Text('${loc.approximate} · ${loc.calorieUnit}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: c.textTertiary)),
        ],
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final NearbyRestaurant restaurant;
  final int remaining;
  final AppLocalizations loc;
  const _RestaurantCard({required this.restaurant, required this.remaining, required this.loc});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dish = foodById(restaurant.suggestedDishId);
    final cals = dish?.typical.calories ?? 0;
    final fits = cals <= remaining;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: fits ? c.accent : c.border, width: fits ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.storefront_outlined, size: 20, color: c.accent),
            const SizedBox(width: 10),
            Text(loc.isAr ? restaurant.nameAr : restaurant.nameEn,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: c.textPrimary)),
            const Spacer(),
            Icon(Icons.place_outlined, size: 14, color: c.textTertiary),
            const SizedBox(width: 2),
            Text('${restaurant.distanceM} م', style: TextStyle(fontSize: 12, color: c.textSecondary)),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: c.surfaceVariant, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (fits)
                    Text(loc.suggestMeal, style: TextStyle(fontSize: 11, color: c.accent2)),
                  if (dish != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(loc.isAr ? dish.nameAr : dish.nameEn,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.textPrimary)),
                    ),
                ]),
              ),
              Text('$cals',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: fits ? c.accent : c.textSecondary)),
              const SizedBox(width: 4),
              Text(loc.calorieUnit, style: TextStyle(fontSize: 11, color: c.textSecondary)),
            ]),
          ),
        ],
      ),
    );
  }
}
