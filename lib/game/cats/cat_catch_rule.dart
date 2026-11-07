/// How a breed has to be caught: a short trait and the explanation shown in
/// the guide. Each breed's rule lives on its CatBreed; the tuning numbers
/// used by the behaviour are below.
class CatCatchRule {
  const CatCatchRule(this.trait, this.how);
  final String trait;
  final String how;

  /// Himalaya refuses fish closer than this and is startled by it.
  static const shyDistance = 120.0;

  /// Black cat refuses fish if another cat is this close to it.
  static const lonelyDistance = 160.0;
  static const scottishMeals = 2;
  static const calicoTaps = 3;

  /// Orange naps this many times longer than the normal catch window.
  static const orangeNap = 2.0;

  // Boss cats: bigger, a little slower, and harder to win over.
  static const bossScale = 1.35;
  static const bossPace = .85;
  static const bossShyScale = 1.4;
  static const bossLonelyScale = 1.3;
  static const bossTaps = 6;

  static int mealsFor(String type, {required bool boss}) => switch (type) {
        'calico' => 0,
        'scottish' => boss ? 4 : scottishMeals,
        'orange' => boss ? 3 : 1,
        _ => boss ? 2 : 1,
      };

  static String bossHint(String type) => switch (type) {
        'orange' => 'Mèo cam béo phải ăn 3 cá',
        'himalaya' => 'Himalaya siêu nhát: 2 cá, đặt thật xa',
        'scottish' => 'Scottish sành ăn phải ăn 4 cá',
        'calico' => 'Tam thể quậy: chạm 6 lần liền',
        'black' => 'Mèo đen bóng ma: 2 cá ở chỗ thật vắng',
        _ => 'Mèo trùm',
      };
}
