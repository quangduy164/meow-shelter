/// Counters collected during a round, used to judge [LevelGoal]s.
class RoundStats {
  int fishUsed = 0;

  /// Times the player made a cat bolt: tapping it, grabbing too early,
  /// dropping fish too close, or holding it too long.
  int startles = 0;
  int wrongDrops = 0;
  int secondsLeft = 0;
}

enum GoalKind { timeLeft, noStartle, fishMax, noWrongBed }

/// One optional mission of a level. Winning gives the first star; each met
/// goal adds one more.
class LevelGoal {
  const LevelGoal.timeLeft(this.value) : kind = GoalKind.timeLeft;
  const LevelGoal.noStartle()
      : kind = GoalKind.noStartle,
        value = 0;
  const LevelGoal.fishMax(this.value) : kind = GoalKind.fishMax;
  const LevelGoal.noWrongBed()
      : kind = GoalKind.noWrongBed,
        value = 0;

  final GoalKind kind;
  final int value;

  String get label => switch (kind) {
        GoalKind.timeLeft => 'Còn ít nhất ${value}s',
        GoalKind.noStartle => 'Không mèo nào giật mình',
        GoalKind.fishMax => 'Dùng tối đa $value cá',
        GoalKind.noWrongBed => 'Không thả nhầm ổ',
      };

  bool met(RoundStats stats) => switch (kind) {
        GoalKind.timeLeft => stats.secondsLeft >= value,
        GoalKind.noStartle => stats.startles == 0,
        GoalKind.fishMax => stats.fishUsed <= value,
        GoalKind.noWrongBed => stats.wrongDrops == 0,
      };
}
