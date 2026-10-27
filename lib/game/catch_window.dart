/// Timings shared by the catch indicator and input handling.
class CatchWindow {
  double ready = 0;
  double grip = 0;
  bool get canCatch => ready > 0;
  void open() => ready = 1.0;
  bool grab() {
    if (!canCatch) return false;
    ready = 0;
    grip = 3.0;
    return true;
  }

  void tick(double dt) {
    ready = (ready - dt).clamp(0.0, 1.0);
    grip = (grip - dt).clamp(0.0, 3.0);
  }

  void clear() {
    ready = 0;
    grip = 0;
  }
}
