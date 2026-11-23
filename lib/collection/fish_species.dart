import 'dart:math' as math;

/// Store whole grams; round only when showing the catch to the player.
String formatFishWeight(int grams) =>
    '${(grams / 1000).toStringAsFixed(2).replaceAll('.', ',')} kg';

enum FishSpecies {
  perch('Cá rô', 24, 'Phổ biến'),
  tilapia('Cá rô phi', 21, 'Phổ biến'),
  carp('Cá chép', 18, 'Phổ biến'),
  catfish('Cá trê', 12, 'Hiếm'),
  koi('Cá koi', 7, 'Quý'),
  goldfish('Cá vàng', 2, 'Cực hiếm'),
  catMew('Cá mèo', 0, 'Huyền thoại'),
  sardine('Cá mòi', 0, 'Phổ biến'),
  mackerel('Cá thu', 0, 'Hiếm'),
  clownfish('Cá hề', 0, 'Quý'),
  pufferfish('Cá nóc', 0, 'Cực hiếm'),
  flipFlop('Dép tông', 8, 'Đồ thất lạc', isJunk: true),
  oldBoot('Ủng cũ', 5, 'Đồ thất lạc', isJunk: true),
  tinCan('Lon rỗng', 3, 'Đồ thất lạc', isJunk: true),
  // Append species to preserve existing save names and enum indices.
  goby('Cá bống', 0, 'Phổ biến'),
  mudskipper('Cá thòi lòi', 0, 'Hiếm'),
  grouper('Cá mú', 0, 'Hiếm'),
  butterflyfish('Cá bướm', 0, 'Quý'),
  cavefish('Cá hang mù', 0, 'Hiếm'),
  lanternfish('Cá đèn lồng', 0, 'Cực hiếm'),
  seaDragon('Cá rồng biển', 0, 'Huyền thoại'),
  moonfish('Cá nguyệt quang', 0, 'Huyền thoại');

  const FishSpecies(this.label, this.weight, this.rarity,
      {this.isJunk = false});
  final String label, rarity;
  final int weight;
  final bool isJunk;

  static const legendary = [catMew, seaDragon, moonfish];

  (int, int) get weightRange => switch (this) {
        goby => (30, 700),
        mudskipper => (40, 450),
        grouper => (600, 18000),
        butterflyfish => (20, 350),
        cavefish => (15, 300),
        lanternfish => (80, 1500),
        perch => (80, 1200),
        tilapia => (150, 3500),
        carp => (400, 10000),
        catfish => (500, 18000),
        koi => (300, 7000),
        goldfish => (20, 500),
        catMew => (800, 25000),
        seaDragon => (1500, 30000),
        moonfish => (400, 12000),
        sardine => (40, 450),
        mackerel => (500, 12000),
        clownfish => (20, 250),
        pufferfish => (150, 3000),
        flipFlop || oldBoot || tinCan => (0, 0),
      };

  int rollGrams(math.Random random) {
    if (isJunk) return 0;
    final (minimum, maximum) = weightRange;
    // Cubic distribution: most catches are small; top 10% sizes occur ~3.5%.
    final t = math.pow(random.nextDouble(), 3).toDouble();
    return minimum + ((maximum - minimum) * t).round();
  }

  double weightFraction(int grams) {
    final (minimum, maximum) = weightRange;
    return isJunk
        ? 0
        : ((grams - minimum) / (maximum - minimum)).clamp(0.0, 1.0);
  }

  /// Line strain per pull, ordered by rarity: common fish are gentle, rare
  /// ones fight harder. Each species keeps its own rhythm in the controller.
  double get pullStrength => switch (this) {
        goby => .65,
        mudskipper => .95,
        grouper => 1.04,
        butterflyfish => 1.22,
        cavefish => 1.0,
        lanternfish => 1.45,
        perch => .64,
        sardine => .66,
        mackerel => 1.02,
        clownfish => 1.25,
        pufferfish => 1.45,
        tilapia => .7,
        carp => .7,
        catfish => 1.02,
        koi => 1.4,
        goldfish => 1.55,
        catMew => 1.3,
        seaDragon => 1.5,
        moonfish => 1.4,
        flipFlop || oldBoot || tinCan => .6,
      };

  double get movementSpeed => switch (this) {
        goby => .8,
        mudskipper => 1.5,
        grouper => .55,
        butterflyfish => 1.3,
        cavefish => .7,
        lanternfish => 1.15,
        perch => 1.35,
        sardine => 1.25,
        mackerel => 1.4,
        clownfish => 1.1,
        pufferfish => .65,
        tilapia => 1.0,
        carp => .62,
        catfish => .48,
        koi => .78,
        goldfish => 1.7,
        catMew => 1.1,
        seaDragon => .9,
        moonfish => .7,
        flipFlop || oldBoot || tinCan => .35,
      };

  double get movementAmplitude => switch (this) {
        goby => .65,
        mudskipper => 1.2,
        grouper => .55,
        butterflyfish => 1.1,
        cavefish => .6,
        lanternfish => .85,
        perch => 1.25,
        sardine => .85,
        mackerel => 1.1,
        clownfish => 1.25,
        pufferfish => .7,
        tilapia => .85,
        carp => .55,
        catfish => .7,
        koi => .45,
        goldfish => 1.45,
        catMew => 1.2,
        seaDragon => 1.1,
        moonfish => .85,
        flipFlop || oldBoot || tinCan => .3,
      };

  bool get isSea =>
      this == sardine ||
      this == mackerel ||
      this == clownfish ||
      this == pufferfish ||
      this == grouper ||
      this == butterflyfish ||
      this == lanternfish ||
      this == seaDragon ||
      this == moonfish;

  static const habitats = [
    'Làng',
    'Sông tre',
    'Rừng ngập mặn',
    'Cửa biển',
    'Vịnh đá',
    'Hang biển',
    'Biển rộng'
  ];

  String get habitat => switch (this) {
        perch || tilapia || carp || goldfish => habitats[0],
        catfish || koi || catMew || oldBoot => habitats[1],
        sardine || mackerel || clownfish || pufferfish => habitats[3],
        goby || mudskipper => habitats[2],
        grouper || butterflyfish => habitats[4],
        cavefish || lanternfish || moonfish => habitats[5],
        seaDragon => habitats[6],
        flipFlop => 'Làng / Biển',
        tinCan => 'Mọi vùng nước',
      };

  bool get nightActive =>
      this == catfish || this == koi || this == lanternfish || this == moonfish;

  /// Affection a camp cat gains from eating one; rarer fish mean more.
  /// Lost items are not food.
  int get affection => switch (this) {
        perch || tilapia || carp || sardine || goby => 2,
        catfish || mackerel || mudskipper || grouper || cavefish => 3,
        koi || clownfish || butterflyfish => 4,
        goldfish || pufferfish || lanternfish => 6,
        catMew || seaDragon || moonfish => 10,
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
