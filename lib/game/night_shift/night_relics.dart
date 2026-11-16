import 'night_cards.dart';

/// Every advertised card combo has an explicit mechanical bonus.
enum NightRelic {
  embers('Than hồng', 22, 'Đèn/cầu tắt còn sáng thêm 4s.', {
    NightCard.longWick: '+2s dư sáng mỗi cấp',
    NightCard.backupPower: '+2s dư sáng mỗi cấp',
    NightCard.sturdyPlanks: '+2s dư sáng mỗi cấp',
    NightCard.lanternRelay: 'Kéo dài đèn trước khi chuyển sang dư sáng',
    NightCard.lastStep: 'Giữ cầu đến khi qua hết, rồi mới dư sáng',
  }),
  bell('Chuông đèn', 26,
      'Lần đầu mở đèn/cầu hoặc đặt mồi mỗi ngăn lồng: giúp 1 mèo gần đó.', {
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
  int get sellPrice => price ~/ 2;
  final Map<NightCard, String> cardCombos;
  Iterable<NightCard> get comboCards => cardCombos.keys;
  String get details => [
        description,
        ...cardCombos.entries.map((e) => '${e.key.title}: ${e.value}'),
        relicCombo,
      ].join('\n');

  String get relicCombo => switch (this) {
        NightRelic.embers =>
          'Dư sáng vẫn nối chuỗi Bùa và giao sáng Lăng kính.',
        NightRelic.bell =>
          'Túi trăng: cùng kích hoạt khi mở đèn/cầu hoặc mồi lồng lần đầu.',
        NightRelic.moonPouch => 'Chuông đèn: vừa tiến bước vừa hồi trợ thủ.',
        NightRelic.feastCharm =>
          'Lăng kính: chuỗi từ 3 thưởng thêm 2 Nguyệt quang.',
        NightRelic.prism =>
          'Bùa liên hoàn: chuỗi từ 3 thưởng thêm 2 Nguyệt quang.',
      };
}
