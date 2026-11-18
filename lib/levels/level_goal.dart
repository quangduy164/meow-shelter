/// Counters collected during a round, used to judge [LevelGoal]s.
class RoundStats {
  int fishUsed = 0;

  /// Times the player made a cat bolt: tapping it, grabbing too early,
  /// dropping fish too close, or holding it too long.
  int startles = 0;
  int wrongDrops = 0;

  /// Kitchen: dishes dropped for a Scottish that wanted something else.
  int wrongDishes = 0;

  /// Garden: times noise sent a Himalaya running back into a bush.
  int retreats = 0;

  /// Playroom: yarn batted away by a non-Calico, and off-beat boss taps.
  int distractions = 0;
  int offBeats = 0;
  int secondsLeft = 0;
}

enum GoalKind {
  timeLeft,
  noStartle,
  fishMax,
  noWrongBed,
  rightDish,
  quiet,
  noDistract,
  onBeat
}

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

  const LevelGoal.noDistract()
      : kind = GoalKind.noDistract,
        value = 0;
  const LevelGoal.onBeat()
      : kind = GoalKind.onBeat,
        value = 0;
  const LevelGoal.quiet()
      : kind = GoalKind.quiet,
        value = 0;
  const LevelGoal.rightDish()
      : kind = GoalKind.rightDish,
        value = 0;

  final GoalKind kind;
  final int value;

  String get label => switch (kind) {
        GoalKind.timeLeft => 'Còn ít nhất ${value}s',
        GoalKind.noStartle => 'Không mèo nào giật mình',
        GoalKind.fishMax => 'Dùng tối đa $value cá',
        GoalKind.noWrongBed => 'Không thả nhầm ổ',
        GoalKind.rightDish => 'Không đưa sai món',
        GoalKind.quiet => 'Không làm Himalaya sợ chạy về bụi',
        GoalKind.noDistract => 'Không để mèo khác hất len',
        GoalKind.onBeat => 'Chạm trùm đúng nhịp',
      };

  bool met(RoundStats stats) => switch (kind) {
        GoalKind.timeLeft => stats.secondsLeft >= value,
        GoalKind.noStartle => stats.startles == 0,
        GoalKind.fishMax => stats.fishUsed <= value,
        GoalKind.noWrongBed => stats.wrongDrops == 0,
        GoalKind.rightDish => stats.wrongDishes == 0,
        GoalKind.quiet => stats.retreats == 0,
        GoalKind.noDistract => stats.distractions == 0,
        GoalKind.onBeat => stats.offBeats == 0,
      };
}
