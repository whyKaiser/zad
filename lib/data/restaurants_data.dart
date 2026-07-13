/// مطاعم قريبة وهمية (للعرض بلا خرائط/GPS). كل مطعم مرتبط بصنف مقترح من القاعدة.
/// لاحقاً: مواقع حقيقية عبر Google Maps + اقتراح بالـ AI.
class NearbyRestaurant {
  final String nameAr;
  final String nameEn;
  final int distanceM;
  final String suggestedDishId;

  const NearbyRestaurant({
    required this.nameAr,
    required this.nameEn,
    required this.distanceM,
    required this.suggestedDishId,
  });
}

const List<NearbyRestaurant> kNearbyRestaurants = [
  NearbyRestaurant(nameAr: 'الطازج', nameEn: 'Al Tazaj', distanceM: 120, suggestedDishId: 'shawarma_chicken'),
  NearbyRestaurant(nameAr: 'ركن الفول', nameEn: 'Foul Corner', distanceM: 200, suggestedDishId: 'foul'),
  NearbyRestaurant(nameAr: 'بيت المندي', nameEn: 'Mandi House', distanceM: 300, suggestedDishId: 'mandi_chicken'),
  NearbyRestaurant(nameAr: 'حمص وفلافل', nameEn: 'Hummus & Falafel', distanceM: 350, suggestedDishId: 'falafel'),
  NearbyRestaurant(nameAr: 'مطعم الكبسة', nameEn: 'Kabsa House', distanceM: 470, suggestedDishId: 'kabsa_chicken'),
];
