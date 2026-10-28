enum FishSpecies {
  perch('Cá rô', 24, 'Phổ biến'),
  tilapia('Cá rô phi', 21, 'Phổ biến'),
  carp('Cá chép', 18, 'Phổ biến'),
  catfish('Cá trê', 12, 'Ít gặp'),
  koi('Cá koi', 7, 'Hiếm'),
  goldfish('Cá vàng', 2, 'Rất hiếm'),
  flipFlop('Dép tông', 8, 'Đồ thất lạc', isJunk: true),
  oldBoot('Ủng cũ', 5, 'Đồ thất lạc', isJunk: true),
  tinCan('Lon rỗng', 3, 'Đồ thất lạc', isJunk: true);

  const FishSpecies(this.label, this.weight, this.rarity,
      {this.isJunk = false});
  final String label, rarity;
  final int weight;
  final bool isJunk;

  static FishSpecies fromRoll(int roll) {
    assert(roll >= 0 && roll < 100);
    for (final fish in values) {
      if (roll < fish.weight) return fish;
      roll -= fish.weight;
    }
    return goldfish;
  }
}
