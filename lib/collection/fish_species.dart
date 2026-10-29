enum FishSpecies {
  perch('Cá rô', 24, 'Phổ biến'),
  tilapia('Cá rô phi', 21, 'Phổ biến'),
  carp('Cá chép', 18, 'Phổ biến'),
  catfish('Cá trê', 12, 'Ít gặp'),
  koi('Cá koi', 7, 'Hiếm'),
  goldfish('Cá vàng', 2, 'Rất hiếm'),
  catMew('Cá mèo', 0, 'Huyền thoại'),
  flipFlop('Dép tông', 8, 'Đồ thất lạc', isJunk: true),
  oldBoot('Ủng cũ', 5, 'Đồ thất lạc', isJunk: true),
  tinCan('Lon rỗng', 3, 'Đồ thất lạc', isJunk: true);

  const FishSpecies(this.label, this.weight, this.rarity,
      {this.isJunk = false});
  final String label, rarity;
  final int weight;
  final bool isJunk;

  double get pullStrength => switch (this) {
        perch => .92,
        tilapia => .82,
        carp => 1.08,
        catfish => 1.18,
        koi => .72,
        goldfish => .58,
        catMew => .96,
        flipFlop || oldBoot || tinCan => .66,
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
