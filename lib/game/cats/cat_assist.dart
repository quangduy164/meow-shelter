/// Temporary helper effects and card bonuses that every cat on the field
/// reads while a night-shift run is on. Plain mutable data owned by the game.
class CatAssist {
  /// Movement factor; the Scottish helper's ice halves it for a while.
  double pace = 1;

  /// Walking speed toward fish (the "scented fish" card).
  double lure = 1;

  /// Black helper: cats do not bolt and do not use their tricks.
  bool calm = false;

  /// Orange helper: the ready and carry timers stand still.
  bool frozen = false;

  void reset() {
    pace = 1;
    lure = 1;
    calm = false;
    frozen = false;
  }
}
