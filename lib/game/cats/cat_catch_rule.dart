/// How each breed has to be caught. Shared by the cat logic and the
/// first-encounter guide so the rules and the explanation never drift apart.
class CatCatchRule {
  const CatCatchRule(this.trait, this.how);
  final String trait;
  final String how;

  static const names = {
    'orange': 'Mèo cam',
    'himalaya': 'Himalaya',
    'scottish': 'Scottish',
    'calico': 'Tam thể',
    'black': 'Mèo đen',
  };

  static const all = {
    'orange': CatCatchRule('Ham ăn',
        'Cho ăn 1 con cá. Ăn xong bé ngủ khò rất lâu, cứ thong thả bế vào ổ.'),
    'himalaya': CatCatchRule(
        'Nhút nhát', 'Đặt cá cách xa bé. Đặt sát quá bé giật mình bỏ chạy.'),
    'scottish':
        CatCatchRule('Kén ăn', 'Phải ăn đủ 2 con cá thì bé mới chịu cho bế.'),
    'calico': CatCatchRule('Ham chơi',
        'Không thèm cá! Chạm vào bé 3 lần liền để chơi cùng, bé mệt là bế được.'),
    'black': CatCatchRule(
        'Cô độc', 'Chỉ ăn cá ở chỗ vắng: quanh con cá không được có mèo khác.'),
  };

  /// Himalaya refuses fish closer than this and is startled by it.
  static const shyDistance = 120.0;

  /// Black cat refuses fish if another cat is this close to it.
  static const lonelyDistance = 160.0;
  static const scottishMeals = 2;
  static const calicoTaps = 3;

  /// Orange naps this many times longer than the normal catch window.
  static const orangeNap = 2.0;
}
