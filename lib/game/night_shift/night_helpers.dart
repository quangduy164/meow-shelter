import 'night_cards.dart';

/// One camp cat brought along as a helper: its active skill on this shift.
/// Names and icons are the breed's home skill so they match Adventure.
class NightHelperSkill {
  const NightHelperSkill(this.effect, this.cooldown, this.duration);

  /// What the skill does on the rescue field, shown in the picker and toast.
  final String effect;
  final double cooldown;

  /// How long the effect lasts; 0 for instant skills.
  final double duration;

  static const of = <String, NightHelperSkill>{
    'orange':
        NightHelperSkill('Đồng hồ chờ bế và bế mèo đứng yên 6 giây', 14, 6),
    'black':
        NightHelperSkill('Mèo không giật mình, không giở chiêu 8 giây', 18, 8),
    'scottish':
        NightHelperSkill('Sân đóng băng: mèo chậm một nửa 6 giây', 12, 6),
    'calico':
        NightHelperSkill('Thả vào ổ nào cũng bật về đúng ổ 10 giây', 20, 10),
    'himalaya':
        NightHelperSkill('2 mèo trên sân no ngay, sẵn sàng để bế', 22, 0),
  };

  /// The same skill worded for the map it is used on.
  static String effectOn(String type, NightMap map) => switch ((type, map)) {
        ('orange', NightMap.warehouse) => 'Mèo trong lồng nán lại 6 giây',
        ('orange', NightMap.reedGarden) => 'Mèo ngừng đổi bụi 6 giây',
        ('orange', NightMap.harbor) => 'Mọi bè đứng yên 6 giây',
        ('orange', NightMap.station) => 'Tàu đứng yên 6 giây',
        ('orange', NightMap.clawMachine) => 'Mèo trong thùng nằm yên 6 giây',
        ('black', NightMap.warehouse) => 'Đóng hụt không làm mèo hoảng 8 giây',
        ('black', NightMap.reedGarden) =>
          'Chạm trúng hay lùa hụt không bị phạt 8 giây',
        ('black', NightMap.harbor) =>
          'Bè đâm đá hay va nhau chỉ dừng lại 8 giây',
        ('black', NightMap.clawMachine) => 'Mèo không né càng 8 giây',
        ('black', NightMap.station) => 'Mèo sai toa đứng chờ chuyến sau 8 giây',
        ('scottish', NightMap.warehouse) =>
          'Cửa sổ chốt lồng hao chậm một nửa 6 giây',
        ('scottish', NightMap.reedGarden) => 'Mèo đổi bụi chậm một nửa 6 giây',
        ('scottish', NightMap.harbor) => 'Dòng nước chảy chậm một nửa 6 giây',
        ('scottish', NightMap.station) => 'Tàu chạy chậm một nửa 6 giây',
        ('scottish', NightMap.clawMachine) => 'Mèo đi chậm một nửa 6 giây',
        ('calico', NightMap.warehouse) =>
          'Chốt được khi mèo đã vào 70% trong 10 giây',
        ('calico', NightMap.reedGarden) => 'Bụi có mèo rung lên trong 10 giây',
        ('calico', NightMap.harbor) => 'Bến nào cũng nhận mọi màu 10 giây',
        ('calico', NightMap.clawMachine) =>
          'Gắp đâu chắc đó, mèo không rơi 10 giây',
        ('calico', NightMap.station) => 'Toa nào cũng nhận mọi giống 10 giây',
        ('himalaya', NightMap.warehouse) =>
          '2 mèo tin mồi, vào lồng nán thêm 2 giây',
        ('himalaya', NightMap.reedGarden) => '2 mèo nhích 1 bụi về phía giỏ',
        ('himalaya', NightMap.harbor) =>
          '2 bè tự chuyển sang luồng bến đúng màu',
        ('himalaya', NightMap.clawMachine) => '2 mèo tự đi về sát miệng thả',
        ('himalaya', NightMap.station) => '2 mèo đang chờ tự ra đúng vạch toa',
        _ => of[type]!.effect,
      };

  /// Recharge time with the current run's card modifier.
  double cooldownFor({double scale = 1}) => cooldown * scale;
}
