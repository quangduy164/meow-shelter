/// Host-owned sleep barrier. Shared timestamps drive the same fade on each
/// device; votes come from live bedroom/sleep states, never a confirmation UI.
class FishingSleep {
  int? startedAt;
  bool committed = false;
  static const delayMs = 400, dawnMs = 1500, durationMs = 3000;

  bool update(
      {required int now, required bool night, required bool allSleeping}) {
    if (committed) {
      if (startedAt != null && now >= startedAt! + durationMs) {
        startedAt = null;
        committed = false;
        return true;
      }
      return false;
    }
    if (!night || !allSleeping) {
      if (startedAt == null) return false;
      startedAt = null;
      return true;
    }
    if (startedAt != null) return false;
    startedAt = now + delayMs;
    return true;
  }

  bool takeDawn(int now, {required bool allSleeping}) {
    if (startedAt == null ||
        committed ||
        !allSleeping ||
        now < startedAt! + dawnMs) {
      return false;
    }
    committed = true;
    return true;
  }

  double darkness(int now,
      {required bool localSleeping, required bool allSleeping}) {
    if (startedAt == null || !localSleeping || (!committed && !allSleeping)) {
      return 0;
    }
    final t = (now - startedAt!) / 1000;
    if (t < 0) return 0;
    if (t < 1.2) return t / 1.2;
    if (t < 1.8) return 1;
    return (1 - (t - 1.8) / 1.2).clamp(0.0, 1.0);
  }

  Map<String, Object>? toJson() => startedAt == null
      ? null
      : {'startedAt': startedAt!, 'committed': committed};
  void read(Object? value, int now) {
    if (value is Map &&
        value['startedAt'] is int &&
        value['committed'] is bool) {
      final start = value['startedAt'] as int;
      if (start >= now - 10000 && start <= now + 2000) {
        startedAt = start;
        committed = value['committed'] as bool;
        return;
      }
    }
    reset();
  }

  void reset() {
    startedAt = null;
    committed = false;
  }
}
