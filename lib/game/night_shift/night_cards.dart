/// Night-shift maps, each built around its own night resource.
enum NightMap {
  backyard('Sân sau dưới trăng',
      'Chạm đèn lồng để thắp; mèo trong vùng sáng không giở chiêu'),
  marketAlley('Hẻm chợ đêm',
      'Giữ độ ồn dưới 100; vùng đèn bảo vệ mèo khi xe đẩy đi qua');

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
      limit: 1, map: NightMap.backyard),
  quietSteps('Đệm chân êm', 'Lỗi thao tác gây ít ồn hơn 50%',
      limit: 2, map: NightMap.marketAlley),
  softWheels('Bánh xe bọc vải', 'Xe đẩy gây ít ồn hơn 30%',
      limit: 2, map: NightMap.marketAlley),
  backupPower('Điện dự phòng', 'Đèn đường sáng thêm 8 giây',
      limit: 2, map: NightMap.marketAlley),
  quietCorner('Góc yên tĩnh', 'Độ ồn giảm nhanh hơn 1 điểm mỗi giây',
      limit: 2, map: NightMap.marketAlley),
  busyMarket('Chợ đông', '+50% xu',
      cost: 'Xe đẩy đến nhanh hơn 25%', limit: 1, map: NightMap.marketAlley);

  const NightCard(this.title, this.perk, {this.cost, this.limit = 3, this.map});
  final String title, perk;
  final String? cost;

  /// Map this card belongs to; null for cards that work everywhere.
  final NightMap? map;

  /// How many times this card can be taken in one run.
  final int limit;
  bool get isDeal => cost != null;
}
