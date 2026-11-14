import 'night_cards.dart';

/// Relics belong to one run and change mechanics rather than card stats.
enum NightRelic {
  embers('Than hồng', 22, 'Đèn tắt còn sáng yếu thêm 4 giây.',
      [NightCard.nightWind, NightCard.brightLantern, NightCard.busyMarket]),
  bell(
      'Chuông đèn',
      26,
      'Lần đầu thắp mỗi đèn trong đêm: 1 mèo gần đèn tiến thêm 1 bước ăn/chơi.',
      [NightCard.extraLantern, NightCard.brightLantern]),
  moonPouch(
      'Túi trăng',
      28,
      'Mỗi lần mây bắt đầu che trăng, giảm 3s hồi chiêu trợ thủ. Cách nhau ít nhất 10s.',
      [NightCard.eagerHelpers]),
  feastCharm(
      'Bùa no bụng',
      34,
      'Cứu mèo trong vùng sáng: 1 mèo gần đó tiến thêm 1 bước ăn/chơi.',
      [NightCard.brightLantern, NightCard.scentedFish]),
  prism(
      'Lăng kính',
      38,
      'Ở chỗ giao giữa ánh trăng và đèn, thanh chờ/bế của mèo đứng yên.',
      [NightCard.fullMoon, NightCard.longWick, NightCard.backupPower]);

  const NightRelic(this.title, this.price, this.description, this.comboCards);
  final String title, description;
  final int price;
  final List<NightCard> comboCards;
}
