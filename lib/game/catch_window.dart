/// Timings shared by the catch indicator and input handling.
class CatchWindow {
  CatchWindow(
      {this.readySeconds = 1, this.gripSeconds = 3, this.unlimited = false});
  final double readySeconds, gripSeconds;
  final bool unlimited;
  double ready = 0;
  double grip = 0;
  bool get canCatch => ready > 0;
  double get readyFraction => (ready / readySeconds).clamp(0.0, 1.0);
  double get gripFraction => (grip / gripSeconds).clamp(0.0, 1.0);
  void open() => ready = readySeconds;
  bool grab() {
    if (!canCatch) return false;
    ready = 0;
    grip = gripSeconds;
    return true;
  }

  void tick(double dt) {
    if (unlimited) return;
    ready = (ready - dt).clamp(0.0, readySeconds);
    grip = (grip - dt).clamp(0.0, gripSeconds);
  }

  void clear() {
    ready = 0;
    grip = 0;
  }
}
