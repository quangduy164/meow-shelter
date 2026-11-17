/// Night-shift maps, each built around its own night resource.
enum NightMap {
  backyard('Sân sau dưới trăng',
      'Chạm đèn lồng để thắp; mèo trong vùng sáng không giở chiêu'),
  marketAlley('Hẻm chợ đêm',
      'Giữ độ ồn dưới 100; vùng đèn bảo vệ mèo khi xe đẩy đi qua'),
  rooftops('Mái nhà', 'Đặt cá ở mái giữa; hạ cầu để mèo hai mái bên sang ăn'),
  warehouse('Kho hàng', 'Đặt mồi trong lồng; chờ tín hiệu xanh rồi chốt cửa'),
  reedGarden('Vườn lau', 'Theo vết lau rung, chạm đúng bụi để tìm mèo trốn');

  const NightMap(this.title, this.rule);
  final String title, rule;
}

/// Upgrade cards picked between nights. Deals ([cost] set) pay more run currency
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
  hotCoins('Khế ước trăng', '+40% Nguyệt quang qua đêm',
      cost: 'Mèo chạy nhanh hơn 15%'),
  nightWind('Gió đêm', '+25% Nguyệt quang qua đêm',
      cost: 'Đèn lồng cháy nhanh gấp đôi', limit: 1, map: NightMap.backyard),
  crowd('Nhà đông vui', '+25% Nguyệt quang qua đêm',
      cost: 'Thêm 1 mèo trên sân', limit: 2),
  hiddenFish('Giấu cá', '+25% Nguyệt quang qua đêm',
      cost: '8 cá/đêm; Kho hàng: chỉ tiêu + 2 cá', limit: 1),
  // Backyard cards: only offered before a night on that map.
  longWick('Bấc dài', 'Đèn lồng cháy lâu hơn 50%',
      limit: 2, map: NightMap.backyard),
  extraLantern('Thêm đèn', 'Thêm 1 cột đèn lồng trên sân',
      limit: 2, map: NightMap.backyard),
  brightLantern('Đèn sáng', 'Vùng sáng của đèn rộng hơn 25%',
      limit: 2, map: NightMap.backyard),
  fullMoon('Trăng tròn', 'Mây không che trăng nữa', limit: 1),
  quietSteps('Đệm chân êm', 'Lỗi thao tác gây ít ồn hơn 50%',
      limit: 2, map: NightMap.marketAlley),
  softWheels('Bánh xe bọc vải', 'Xe đẩy gây ít ồn hơn 30%',
      limit: 2, map: NightMap.marketAlley),
  backupPower('Điện dự phòng', 'Đèn đường sáng thêm 8 giây',
      limit: 2, map: NightMap.marketAlley),
  quietCorner('Góc yên tĩnh', 'Độ ồn giảm nhanh hơn 1 điểm mỗi giây',
      limit: 2, map: NightMap.marketAlley),
  busyMarket('Chợ đông', '+25% Nguyệt quang qua đêm',
      cost: 'Xe đẩy đến nhanh hơn 25%', limit: 1, map: NightMap.marketAlley),
  sturdyPlanks('Ván chắc', 'Cầu ván mở lâu thêm 8 giây',
      limit: 2, map: NightMap.rooftops),
  quickCarpenter('Thợ mộc nhanh', 'Cầu ván hồi nhanh hơn 50%',
      limit: 2, map: NightMap.rooftops),
  widePlanks('Ván rộng', 'Lối đi trên cầu rộng hơn 50%',
      limit: 2, map: NightMap.rooftops),
  railLights('Đèn lan can', 'Ánh sáng quanh cầu rộng hơn',
      limit: 1, map: NightMap.rooftops),
  stormyRoof('Gió mái', '+25% Nguyệt quang qua đêm',
      cost: 'Cầu ván chỉ mở nửa thời gian', limit: 1, map: NightMap.rooftops),
  lanternRelay('Đèn nối tiếp', 'Bật đèn: kéo dài đèn gần nhất thêm 2s/cấp',
      limit: 2, map: NightMap.backyard),
  moonEcho('Đốm trăng lưu lại', 'Ánh trăng để lại đốm sáng 3s; thêm 2s/cấp',
      limit: 2, map: NightMap.backyard),
  restingLight('Góc nghỉ', 'Trong sáng, thanh chờ/bế chậm thêm 33%/50%',
      limit: 2, map: NightMap.backyard),
  fewerLanterns('Đèn ít', '+25% Nguyệt quang qua đêm',
      cost: 'Bớt 1 đèn ở sân sau', limit: 1, map: NightMap.backyard),
  cartFish('Thùng cá trên xe', 'Mỗi chuyến xe xong thả thêm 1 cá miễn phí',
      limit: 1, map: NightMap.marketAlley),
  gentleCart('Chuyến xe êm', 'Xe đi chậm hơn, gây ít ồn hơn 50%',
      limit: 1, map: NightMap.marketAlley),
  afterHours('Sau giờ chợ', 'Khoảng yên tĩnh sau xe dài thêm 2s/cấp',
      limit: 2, map: NightMap.marketAlley),
  closingBell('Chuông tan chợ', 'Cứu khi yên tĩnh: giảm 8 ồn/cấp',
      limit: 2, map: NightMap.marketAlley),
  pairedBridges('Cầu đôi', 'Mở cầu: cầu đối diện cùng hàng mở 6s',
      limit: 1, map: NightMap.rooftops),
  lastStep('Nhịp cuối', 'Cầu giữ mở khi có mèo đi trên khe',
      limit: 1, map: NightMap.rooftops),
  sharedFish('Mâm cá chung', 'Cá mái giữa có 2 phần ăn lần lượt',
      limit: 1, map: NightMap.rooftops),
  autoBridge('Cầu tự động', 'Mỗi cầu tự mở lại 1 lần khi hồi xong',
      limit: 1, map: NightMap.rooftops),
  relayRescue('Tiếp sức', 'Cứu mèo: trợ thủ hồi nhanh 2s/cấp', limit: 2),
  fishReserve('Cá dự trữ', 'Cá chưa ai nhận sau 12s: hoàn cá đã trả', limit: 1),
  rescueRhythm(
      'Cứu đúng nhịp', 'Cứu nối trong 8s: +1 Nguyệt quang/cấp; tối đa 6/đêm',
      limit: 2),
  preparedBait('Chuẩn bị kỹ', 'Đầu đêm có sẵn 1 cá miễn phí trên sân',
      limit: 1),
  nurturingMeal('Chăm sóc lan tỏa', 'Mỗi bữa ăn: mèo gần chờ bế thêm 2s/cấp',
      limit: 2),
  quietDoors('Cửa êm', 'Đóng hụt: vùng hoảng nhỏ hơn 50%/cấp',
      limit: 2, map: NightMap.warehouse),
  twinCages('Hai ngăn', 'Mỗi lồng có 2 ngăn, chốt từng ngăn riêng',
      limit: 1, map: NightMap.warehouse),
  deepBait('Mồi sâu', 'Mèo vào chậm hơn 25%, nán lại thêm 0.6s/cấp',
      limit: 2, map: NightMap.warehouse),
  linkedDoors(
      'Dây giật chung', 'Chốt thêm ngăn cùng hàng của lồng kế tiếp nếu có mèo',
      limit: 1, map: NightMap.warehouse),
  dewTracks('Dấu chân sương', 'Vết mèo đổi bụi hiện lâu thêm 2s/cấp',
      limit: 2, map: NightMap.reedGarden),
  stillReeds('Lau lặng gió', 'Mèo đổi bụi chậm hơn 30%/cấp',
      limit: 2, map: NightMap.reedGarden),
  softParting('Rẽ lau nhẹ', 'Chạm hụt không làm mèo gần đó chạy bụi',
      limit: 1, map: NightMap.reedGarden),
  reedBell('Chuông lau', 'Mỗi 8s, một bụi có mèo rung mạnh',
      limit: 1, map: NightMap.reedGarden);

  const NightCard(this.title, this.perk, {this.cost, this.limit = 3, this.map});
  final String title, perk;
  final String? cost;

  /// Map this card belongs to; null for cards that work everywhere.
  final NightMap? map;

  /// How many times this card can be taken in one run.
  final int limit;
  bool get isDeal => cost != null;
  bool availableOn(NightMap next) =>
      (map == null || map == next) &&
      (next != NightMap.warehouse ||
          !const [warmHug, patience, wideBeds, nailedBeds, nurturingMeal]
              .contains(this));
  String? get comboHint => switch (this) {
        lanternRelay => 'Ghép Bấc dài để giữ nhiều đèn sáng cùng lúc.',
        moonEcho => 'Ghép Lăng kính: đốm trăng vẫn tạo giao sáng.',
        restingLight => 'Ghép Đèn sáng để mở rộng góc nghỉ.',
        fewerLanterns => 'Ghép Đèn nối tiếp để bù số đèn ít.',
        cartFish => 'Ghép Cá thơm để mèo tới cá xe thả nhanh hơn.',
        gentleCart => 'Ghép Bánh xe bọc vải để giảm thêm ồn.',
        afterHours => 'Ghép Chuông tan chợ để cứu và giảm ồn lâu hơn.',
        closingBell => 'Ghép Cứu đúng nhịp để vừa giảm ồn vừa kiếm thêm.',
        pairedBridges => 'Ghép Mâm cá chung để đón mèo từ hai phía.',
        lastStep => 'Ghép Ván rộng để mèo qua cầu dễ hơn.',
        sharedFish =>
          'Ghép Cá dự trữ: hoàn cá chưa ai nhận, không hoàn phần đã ăn.',
        autoBridge => 'Ghép Chuông đèn: lần tự mở lại có nhịp chuông.',
        relayRescue => 'Ghép Trợ thủ hăng hái để dùng kỹ năng thường xuyên.',
        fishReserve => 'Cá miễn phí và cá đã có mèo nhận không được hoàn.',
        rescueRhythm => 'Vòng tay ấm kéo dài cửa sổ nối chuỗi thêm 2s/cấp.',
        preparedBait => 'Ghép Cá thơm để bắt đầu đêm nhanh hơn.',
        nurturingMeal => 'Ghép Cá thơm để tăng tầm lan tỏa 35%/cấp.',
        quietDoors => 'Ghép trợ thủ mèo đen để hạn chế mèo gần giật mình.',
        twinCages => 'Ghép Dây giật chung để canh nhiều ngăn cùng lúc.',
        deepBait => 'Ghép Cá thơm để bù thời gian dẫn mèo vào lồng.',
        linkedDoors => 'Ghép Mồi sâu để hai mèo cùng ở trong cửa sổ chốt.',
        dewTracks => 'Ghép Lau lặng gió để lần theo từng bước dễ hơn.',
        stillReeds => 'Ghép Cá thơm để dụ mèo vào bụi đã chọn.',
        softParting => 'Ghép trợ thủ mèo đen để dò bụi an toàn hơn.',
        reedBell => 'Ghép Chuông đèn: lần tìm thấy đầu tiên kích hoạt chuông.',
        _ => null,
      };
}
