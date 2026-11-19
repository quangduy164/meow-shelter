import 'night_cards.dart';

/// Every advertised card combo has an explicit mechanical bonus.
enum NightRelic {
  embers('Than hồng', 22,
      'Kéo dài lợi thế của map: đèn, cầu, lồng, vết, bè, tàu.', {
    NightCard.longWick: '+2s dư sáng mỗi cấp',
    NightCard.backupPower: '+1s yên tĩnh sau xe mỗi cấp',
    NightCard.sturdyPlanks: '+2s dư sáng mỗi cấp',
    NightCard.lanternRelay: 'Kéo dài đèn trước khi chuyển sang dư sáng',
    NightCard.lastStep: 'Giữ cầu đến khi qua hết, rồi mới dư sáng',
    NightCard.deepBait: '+2s dư sáng mỗi cấp',
    NightCard.dewTracks: '+2s dư sáng mỗi cấp',
    NightCard.slowCurrent: '+2s dư sáng mỗi cấp',
    NightCard.longStop: '+2s dư sáng mỗi cấp',
  }),
  bell('Chuông đèn', 26,
      'Lần đầu dùng mỗi điểm điều khiển: giúp 1 mèo gần đó.', {
    NightCard.reedBell: '+1 mèo nhận chuông',
    NightCard.porter: '+1 mèo nhận chuông',
    NightCard.extraLantern: '+1 mèo nhận chuông/cấp (tối đa 3)',
    NightCard.widePlanks: '+1 mèo nhận chuông/cấp (tối đa 3)',
    NightCard.brightLantern: '+25% tầm chuông mỗi cấp',
    NightCard.railLights: '+50% tầm chuông',
    NightCard.pairedBridges: 'Hai cầu mở lần đầu đều phát nhịp chuông',
    NightCard.autoBridge: 'Lần tự mở lại phát thêm nhịp chuông',
  }),
  moonPouch(
      'Túi trăng',
      28,
      'Mở đèn/cầu hoặc mồi ngăn lồng lần đầu: hồi trợ thủ 2s. Mây tới: hồi 3s (cách 10s).',
      {
        NightCard.fullMoon: 'Nhịp mở đèn/cầu hồi thêm 2s',
        NightCard.eagerHelpers: 'Mỗi nhịp hồi thêm 1s mỗi cấp',
        NightCard.relayRescue: 'Thêm hồi trợ thủ mỗi lần cứu mèo',
        NightCard.autoBridge: 'Lần cầu tự mở lại cũng phát nhịp hồi',
      }),
  feastCharm('Bùa liên hoàn', 34,
      'Cứu trong sáng: mèo gần tiến 1 bước. Nối trong 8s: tác động 2 mèo.', {
    NightCard.warmHug: '+2s nối chuỗi mỗi cấp',
    NightCard.scentedFish: '+35% tầm lan mỗi cấp',
    NightCard.patience: 'Chuỗi từ 3: tác động thêm 1 mèo',
    NightCard.rescueRhythm: 'Cùng nối chuỗi cứu để kiếm Nguyệt quang',
    NightCard.nurturingMeal: 'Nhịp ăn do Bùa cũng kéo dài chờ bế cho mèo gần',
  }),
  prism(
      'Lăng kính',
      38,
      'Giao trăng và đèn/lồng: giữ thanh chờ/bế hoặc chốt lồng. Cứu tại đó: +3 Nguyệt quang.',
      {
        NightCard.fullMoon: '+2 Nguyệt quang mỗi lần cứu ở giao sáng',
        NightCard.hotCoins: '+1 Nguyệt quang mỗi cấp ở giao sáng',
        NightCard.moonEcho: 'Đốm trăng giao đèn cũng kích hoạt Lăng kính',
      });

  const NightRelic(this.title, this.price, this.description, this.cardCombos);
  final String title, description;
  final int price;
  final Map<NightCard, String> cardCombos;

  /// What each level above 1 adds (levels go up to 3).
  String get levelPerk => switch (this) {
        embers => '+2s dư sáng',
        bell => '+1 mèo nhận chuông, +20% tầm',
        moonPouch => '+1s hồi trợ thủ mỗi nhịp',
        feastCharm => '+2s cửa sổ nối chuỗi',
        prism => '+1 Nguyệt quang mỗi lần cứu ở giao sáng',
      };
  Iterable<NightCard> get comboCards => cardCombos.keys;
  String get details => [
        description,
        ...cardCombos.entries.map((e) => '${e.key.title}: ${e.value}'),
        relicCombo,
      ].join('\n');

  /// The same relic, worded for one map. Shown in the night briefing.
  String effectOn(NightMap map) => switch (this) {
        NightRelic.embers => switch (map) {
            NightMap.backyard => 'Đèn tắt còn sáng thêm',
            NightMap.marketAlley => 'Yên tĩnh sau xe lâu hơn',
            NightMap.rooftops => 'Cầu thu lại còn sáng thêm',
            NightMap.warehouse => 'Mèo nán trong lồng lâu hơn',
            NightMap.reedGarden => 'Vết chân hiện lâu hơn',
            NightMap.harbor => 'Cá neo bè lâu hơn',
            NightMap.station => 'Tàu dừng ga lâu hơn',
            NightMap.clawMachine => 'Cá giữ mèo tụ lâu hơn',
          },
        NightRelic.bell => switch (map) {
            NightMap.reedGarden => '${map.control}: mèo nhích về giỏ',
            NightMap.harbor => '${map.control}: giữ bè gần 2s',
            NightMap.station => '${map.control}: mèo tự ra vạch',
            NightMap.clawMachine => '${map.control}: mèo gần nằm yên',
            NightMap.warehouse => '${map.control}: mèo gần tin mồi',
            _ => '${map.control}: mèo gần tiến bước',
          },
        NightRelic.moonPouch => '${map.control}: trợ thủ hồi 2s',
        NightRelic.feastCharm => 'Cứu liên tiếp: giúp mèo gần',
        NightRelic.prism => 'Cứu ở giao trăng và ${map.light}: +3',
      };

  String get relicCombo => switch (this) {
        NightRelic.embers =>
          'Dư sáng vẫn nối chuỗi Bùa và giao sáng Lăng kính.',
        NightRelic.bell => 'Túi trăng: cùng kích hoạt ở lần dùng đầu tiên.',
        NightRelic.moonPouch => 'Chuông đèn: vừa tiến bước vừa hồi trợ thủ.',
        NightRelic.feastCharm =>
          'Lăng kính: chuỗi từ 3 thưởng thêm 2 Nguyệt quang.',
        NightRelic.prism =>
          'Bùa liên hoàn: chuỗi từ 3 thưởng thêm 2 Nguyệt quang.',
      };
}
