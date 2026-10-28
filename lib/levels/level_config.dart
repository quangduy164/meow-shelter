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
  });

  final int id;
  final String name;
  final List<String> catTypes;
  final int timeLimit;
  final bool isTutorial, allowRun;
  final double speedMultiplier, readySeconds, gripSeconds;
  final int skillTier;

  CatSkill skillFor(String type) => switch (type) {
        'orange' when skillTier >= 1 => CatSkill.sprint,
        'himalaya' when skillTier >= 2 => CatSkill.feint,
        'scottish' when skillTier >= 2 => CatSkill.zigzag,
        'calico' when skillTier >= 3 => CatSkill.slippery,
        'black' when skillTier >= 3 => CatSkill.vanish,
        _ => CatSkill.none,
      };
}
