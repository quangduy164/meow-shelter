import '../game/cats/cat_skill.dart';

class LevelConfig {
  const LevelConfig({
    required this.id,
    required this.catTypes,
    required this.timeLimit,
    required this.name,
    this.isTutorial = false,
    this.speedMultiplier = 1,
    this.readySeconds = 3,
    this.gripSeconds = 4,
    this.allowRun = true,
    this.skillTier = 0,
    this.isInfinite = false,
  });

  final int id;
  final String name;
  final List<String> catTypes;
  final int timeLimit;
  final bool isTutorial, allowRun;
  final bool isInfinite;
  final double speedMultiplier, readySeconds, gripSeconds;
  final int skillTier;

  int get shelterCount => catTypes.toSet().length;

  String get mission => isInfinite
      ? 'Cứu càng nhiều mèo'
      : 'Cứu ${catTypes.length} mèo vào $shelterCount ổ';

  CatSkill skillFor(String type) => switch (type) {
        'orange' when skillTier >= 1 => CatSkill.sprint,
        'himalaya' when skillTier >= 2 => CatSkill.feint,
        'scottish' when skillTier >= 2 => CatSkill.zigzag,
        'calico' when skillTier >= 3 => CatSkill.slippery,
        'black' when skillTier >= 3 => CatSkill.vanish,
        _ => CatSkill.none,
      };

  LevelConfig forInfiniteProgress(int rescued) {
    final wave = rescued ~/ 5;
    return LevelConfig(
      id: id,
      name: name,
      catTypes: catTypes,
      timeLimit: timeLimit,
      isTutorial: isTutorial,
      speedMultiplier: (speedMultiplier + wave * .10).clamp(.8, 1.6),
      readySeconds: (readySeconds - wave * .18).clamp(1.4, readySeconds),
      gripSeconds: (gripSeconds - wave * .12).clamp(2.2, gripSeconds),
      allowRun: allowRun,
      skillTier: (skillTier + wave).clamp(0, 3),
      isInfinite: isInfinite,
    );
  }
}
