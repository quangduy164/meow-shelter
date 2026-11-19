enum FishSpecies {
  perch('Cá rô', 24, 'Phổ biến'),
  tilapia('Cá rô phi', 21, 'Phổ biến'),
  carp('Cá chép', 18, 'Phổ biến'),
  catfish('Cá trê', 12, 'Hiếm'),
  koi('Cá koi', 7, 'Quý'),
  goldfish('Cá vàng', 2, 'Cực hiếm'),
  catMew('Cá mèo', 0, 'Huyền thoại'),
  flipFlop('Dép tông', 8, 'Đồ thất lạc', isJunk: true),
  oldBoot('Ủng cũ', 5, 'Đồ thất lạc', isJunk: true),
  tinCan('Lon rỗng', 3, 'Đồ thất lạc', isJunk: true);

  const FishSpecies(this.label, this.weight, this.rarity,
      {this.isJunk = false});
  final String label, rarity;
  final int weight;
  final bool isJunk;

  /// Line strain per pull, ordered by rarity: common fish are gentle, rare
  /// ones fight harder. Each species keeps its own rhythm in the controller.
  double get pullStrength => switch (this) {
        perch => .64,
        tilapia => .7,
        carp => .7,
        catfish => 1.02,
        koi => 1.4,
        goldfish => 1.55,
        catMew => 1.3,
        flipFlop || oldBoot || tinCan => .6,
      };

  double get movementSpeed => switch (this) {
        perch => 1.35,
        tilapia => 1.0,
        carp => .62,
        catfish => .48,
        koi => .78,
        goldfish => 1.7,
        catMew => 1.1,
        flipFlop || oldBoot || tinCan => .35,
      };

  double get movementAmplitude => switch (this) {
        perch => 1.25,
        tilapia => .85,
        carp => .55,
        catfish => .7,
        koi => .45,
        goldfish => 1.45,
        catMew => 1.2,
        flipFlop || oldBoot || tinCan => .3,
      };

  bool get nightActive => this == catfish || this == koi;

  /// Affection a camp cat gains from eating one; rarer fish mean more.
  /// Lost items are not food.
  int get affection => switch (this) {
        perch || tilapia || carp => 2,
        catfish => 3,
        koi => 4,
        goldfish => 6,
        catMew => 10,
        flipFlop || oldBoot || tinCan => 0,
      };

  static FishSpecies fromRollAtTime(int roll, double hour) {
    assert(roll >= 0);
    final weights = <FishSpecies, int>{
      for (final fish in values) fish: fish.weight,
    };
    weights[catMew] = 1;
    final night = hour < 6 || hour >= 18;
    if (night) {
      weights[catfish] = 20;
      weights[koi] = 12;
      weights[goldfish] = 4;
      weights[catMew] = 2;
      weights[perch] = 14;
    } else if (hour >= 5 && hour < 9) {
      weights[carp] = 24;
      weights[koi] = 10;
    } else {
      weights[perch] = 27;
      weights[tilapia] = 24;
    }
    final total = weights.values.fold<int>(0, (sum, weight) => sum + weight);
    var ticket = roll % total;
    for (final fish in values) {
      ticket -= weights[fish]!;
      if (ticket < 0) return fish;
    }
    return values.last;
  }

  static FishSpecies fromRoll(int roll) {
    assert(roll >= 0 && roll < 100);
    for (final fish in values) {
      if (roll < fish.weight) return fish;
      roll -= fish.weight;
    }
    return goldfish;
  }
}
