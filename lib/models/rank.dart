enum Rank {
  iron,
  bronze,
  silver,
  gold,
  platinum,
  diamond,
  master,
  grandChampion,
}

extension RankX on Rank {
  String get nameAr => switch (this) {
    Rank.iron => 'الحديد',
    Rank.bronze => 'البرونز',
    Rank.silver => 'الفضة',
    Rank.gold => 'الذهب',
    Rank.platinum => 'البلاتين',
    Rank.diamond => 'الماس',
    Rank.master => 'الماستر',
    Rank.grandChampion => 'البطل الأكبر',
  };

  String get nameEn => switch (this) {
    Rank.iron => 'Iron',
    Rank.bronze => 'Bronze',
    Rank.silver => 'Silver',
    Rank.gold => 'Gold',
    Rank.platinum => 'Platinum',
    Rank.diamond => 'Diamond',
    Rank.master => 'Master',
    Rank.grandChampion => 'Grand Champion',
  };

  String get emoji => switch (this) {
    Rank.iron => '⚙️',
    Rank.bronze => '🥉',
    Rank.silver => '🥈',
    Rank.gold => '🥇',
    Rank.platinum => '💠',
    Rank.diamond => '💎',
    Rank.master => '🏆',
    Rank.grandChampion => '👑',
  };

  int get minPoints => switch (this) {
    Rank.iron => 0,
    Rank.bronze => 100,
    Rank.silver => 300,
    Rank.gold => 600,
    Rank.platinum => 1000,
    Rank.diamond => 1500,
    Rank.master => 2200,
    Rank.grandChampion => 3000,
  };

  int get maxPoints => index < Rank.values.length - 1
      ? Rank.values[index + 1].minPoints
      : 999999;
}

Rank rankFromPoints(int points) {
  final all = Rank.values.reversed;
  for (final r in all) {
    if (points >= r.minPoints) return r;
  }
  return Rank.iron;
}
