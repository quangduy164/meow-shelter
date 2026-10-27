class LevelConfig {
  const LevelConfig({
    required this.id,
    required this.catTypes,
    required this.timeLimit,
    required this.lives,
    required this.name,
  });

  final int id;
  final String name;
  final List<String> catTypes;
  final int timeLimit;
  final int lives;
}
