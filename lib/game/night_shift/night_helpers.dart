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

  /// Recharge time with the current run's card modifier.
  double cooldownFor({double scale = 1}) => cooldown * scale;
}
