import 'dart:math';

/// Temporary helper effects and card bonuses that every cat on the field
/// reads while a night-shift run is on. Plain mutable data owned by the game.
class CatAssist {
  /// Movement factor; the Scottish helper's ice halves it for a while.
  double pace = 1;

  /// Walking speed toward fish (the "scented fish" card).
  double lure = 1;

  /// Black helper: cats do not bolt and do not use their tricks.
  bool calm = false;

  /// Orange helper: the ready and carry timers stand still.
  bool frozen = false;

  void reset() {
    pace = 1;
    lure = 1;
    calm = false;
    frozen = false;
  }
}

/// One camp cat brought along as a helper: its active skill on this shift.
/// Names and icons are the breed's home skill so they match Adventure.
class NightHelperSkill {
  const NightHelperSkill(this.effect, this.cooldown, this.duration);

  /// What the skill does on the rescue field, shown in the picker and toast.
  final String effect;
  final double cooldown;

  /// How long the effect lasts; 0 for instant skills.
  final double duration;

  static const bondBonus = 4.0;

  static const of = <String, NightHelperSkill>{
    'orange':
        NightHelperSkill('Đồng hồ chờ bế và bế mèo đứng yên 6 giây', 18, 6),
    'black':
        NightHelperSkill('Mèo không giật mình, không giở chiêu 8 giây', 22, 8),
    'scottish':
        NightHelperSkill('Sân đóng băng: mèo chậm một nửa 6 giây', 16, 6),
    'calico':
        NightHelperSkill('Thả vào ổ nào cũng bật về đúng ổ 10 giây', 24, 10),
    'himalaya':
        NightHelperSkill('2 mèo trên sân no ngay, sẵn sàng để bế', 26, 0),
  };

  /// Recharge time; a bonded camp cat recharges faster.
  double cooldownFor({required bool bonded, double scale = 1}) =>
      (cooldown - (bonded ? bondBonus : 0)) * scale;
}

/// Night-shift maps, each built around its own night resource.
enum NightMap {
  backyard('Sân sau dưới trăng',
      'Chạm đèn lồng để thắp; mèo trong vùng sáng không giở chiêu');

  const NightMap(this.title, this.rule);
  final String title, rule;
}

/// Upgrade cards picked between nights. Deals ([cost] set) pay more coins
/// but make the shift harder.
enum NightCard {
  scentedFish('Cá thơm', 'Mèo chạy tới cá nhanh hơn 35%'),
  warmHug('Vòng tay ấm', 'Bế mèo được lâu hơn 35%'),
  patience('Mèo kiên nhẫn', 'Mèo no chờ bế lâu hơn 35%'),
  lazyLunch('Bữa trưa no nê', 'Mèo đi chậm hơn 12%'),
  wideBeds('Ổ rộng', 'Ổ to hơn 25%, dễ thả trúng', limit: 2),
  fishBasket('Giỏ cá', 'Đêm giới hạn cá có thêm 4 cá'),
  nailedBeds('Ổ đóng đinh', 'Ổ không bao giờ dời chỗ', limit: 1),
  longNight('Đêm dài', 'Mỗi đêm thêm 10 giây'),
  eagerHelpers('Trợ thủ hăng hái', 'Kỹ năng trợ thủ hồi nhanh hơn 25%',
      limit: 2),
  hotCoins('Tiền nóng', '+100% xu', cost: 'Mèo chạy nhanh hơn 15%'),
  nightWind('Gió đêm', '+50% xu',
      cost: 'Đèn lồng cháy nhanh gấp đôi', limit: 1, map: NightMap.backyard),
  crowd('Nhà đông vui', '+50% xu', cost: 'Thêm 1 mèo trên sân', limit: 2),
  hiddenFish('Giấu cá', '+50% xu', cost: 'Mỗi đêm chỉ có 8 cá', limit: 1),
  // Backyard cards: only offered before a night on that map.
  longWick('Bấc dài', 'Đèn lồng cháy lâu hơn 50%',
      limit: 2, map: NightMap.backyard),
  extraLantern('Thêm đèn', 'Thêm 1 cột đèn lồng trên sân',
      limit: 2, map: NightMap.backyard),
  brightLantern('Đèn sáng', 'Vùng sáng của đèn rộng hơn 25%',
      limit: 2, map: NightMap.backyard),
  fullMoon('Trăng tròn', 'Mây không che trăng nữa',
      limit: 1, map: NightMap.backyard);

  const NightCard(this.title, this.perk, {this.cost, this.limit = 3, this.map});
  final String title, perk;
  final String? cost;

  /// Map this card belongs to; null for cards that work everywhere.
  final NightMap? map;

  /// How many times this card can be taken in one run.
  final int limit;
  bool get isDeal => cost != null;
}

/// Progress of one night-shift run: the current night, its quota and every
/// bonus from the cards picked so far.
class NightRun {
  NightRun(this.helpers);

  /// Camp cats brought along (one or two breed ids).
  final List<String> helpers;
  final cards = <NightCard>[];
  int night = 1;
  int rescuedTonight = 0, spawnedTonight = 0;
  int totalRescued = 0, coins = 0;

  int count(NightCard card) => cards.where((c) => c == card).length;
  bool has(NightCard card) => cards.contains(card);

  // Card bonuses.
  double get speed =>
      pow(.88, count(NightCard.lazyLunch)) *
      pow(1.15, count(NightCard.hotCoins)).toDouble();
  double get grip => 1 + .35 * count(NightCard.warmHug);
  double get ready => 1 + .35 * count(NightCard.patience);
  double get lure => 1 + .35 * count(NightCard.scentedFish);
  double get bedScale => 1 + .25 * count(NightCard.wideBeds);
  int get extraFish => 4 * count(NightCard.fishBasket);
  double get cooldownScale =>
      pow(.75, count(NightCard.eagerHelpers)).toDouble();
  double get coinBonus =>
      count(NightCard.hotCoins) +
      .5 *
          (count(NightCard.nightWind) +
              count(NightCard.crowd) +
              count(NightCard.hiddenFish));

  // The night itself.
  int get quota => min(3 + night, 12);

  /// Cats on the field at once.
  int get fieldSize =>
      min(min(2 + night ~/ 2, 5) + count(NightCard.crowd), quota);
  int get seconds => 22 + quota * 8 + 10 * count(NightCard.longNight);

  /// Map of the given night. One map for now; later maps join the rotation.
  NightMap mapFor(int night) => NightMap.backyard;
  NightMap get map => mapFor(night);

  // Backyard bonuses.
  int get lanterns => 3 + count(NightCard.extraLantern);
  double get lanternBurn =>
      10 *
      (1 + .5 * count(NightCard.longWick)) /
      (has(NightCard.nightWind) ? 2 : 1);
  double get lanternLight => 1 + .25 * count(NightCard.brightLantern);

  /// Every fifth night ends with a boss cat.
  bool get bossNight => night % 5 == 0;

  /// Three cards for the night ahead on [next]: one general upgrade, one
  /// card for that map and one deal, filled from the others when a group
  /// has run out.
  List<NightCard> offer(Random random, NightMap next) {
    final open = NightCard.values
        .where((c) => count(c) < c.limit && (c.map == null || c.map == next))
        .toList()
      ..shuffle(random);
    final general = open.where((c) => !c.isDeal && c.map == null).toList();
    final mapCards = open.where((c) => !c.isDeal && c.map != null).toList();
    final deals = open.where((c) => c.isDeal).toList();
    final picks = <NightCard>[
      ...general.take(1),
      ...mapCards.take(1),
      ...deals.take(1),
    ];
    for (final card in [...general, ...mapCards, ...deals]) {
      if (picks.length >= 3) break;
      if (!picks.contains(card)) picks.add(card);
    }
    return picks;
  }
}
