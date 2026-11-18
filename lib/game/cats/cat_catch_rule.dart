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

  /// Non-Calico cats this close to a stopped ball of yarn run to bat it.
  static const yarnPull = 170.0;

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

  /// The kitchen boss orders a menu in sequence and changes its mind once.
  static const kitchenBossCourses = 3, kitchenCourses = 2;

  static String bossHint(String type,
          {bool dishes = false,
          bool bushes = false,
          bool toys = false,
          bool moon = false,
          bool yard = false}) =>
      switch (type) {
        'orange' when yard =>
          'Mèo cam béo phải ăn 3 cá, no rồi sẽ về ổ rơm ngủ, ngủ rồi mới bế được',
        'black' when moon =>
          'Mèo đen bóng ma nhảy giữa các góc tối; dấu chân tím chỉ chỗ sắp hiện',
        'calico' when toys =>
          'Tam thể quậy: chạm đúng nhịp vòng vàng 6 lần, sai nhịp là bé hất đồ chơi',
        'himalaya' when bushes =>
          'Himalaya siêu nhát lẻn từ bụi này sang bụi khác: thả cá thật xa để chặn đường',
        'scottish' when dishes =>
          'Scottish sành ăn gọi 3 món theo thứ tự, ăn xong món đầu sẽ đổi ý',
        'orange' => 'Mèo cam béo phải ăn 3 cá',
        'himalaya' => 'Himalaya siêu nhát: 2 cá, đặt thật xa',
        'scottish' => 'Scottish sành ăn phải ăn 4 cá',
        'calico' => 'Tam thể quậy: chạm 6 lần liền',
        'black' => 'Mèo đen bóng ma: 2 cá ở chỗ thật vắng',
        _ => 'Mèo trùm',
      };
}
