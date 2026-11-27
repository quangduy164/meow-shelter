/// Change detection for presence packets, independent of animation frames.
class FishingPresenceGate {
  static const intervalMs = 125, heartbeatMs = 1000;
  static const movementThreshold = 3.0;
  Map<String, Object>? _sent, _observed;
  int? _attemptAt, _sentAt;
  static const _coordinates = {'x', 'y', 'bx', 'by'};

  bool shouldSend(Map<String, Object> state, int now) {
    final previous = _observed;
    _observed = state;
    if (_attemptAt != null && now - _attemptAt! < intervalMs) return false;
    final sent = _sent;
    if (sent == null || _sentAt == null || now - _sentAt! >= heartbeatMs) {
      return true;
    }
    for (final entry in state.entries) {
      if (entry.key != 'stamp' &&
          entry.key != 'frame' &&
          !_coordinates.contains(entry.key) &&
          sent[entry.key] != entry.value) {
        return true;
      }
    }
    if (_distanceSquared(state, sent, 'x', 'y') >=
            movementThreshold * movementThreshold ||
        _distanceSquared(state, sent, 'bx', 'by') >=
            movementThreshold * movementThreshold) {
      return true;
    }
    // Flush the exact endpoint after one stationary sample, even below 3 units.
    return previous != null &&
        _coordinates.every((key) => state[key] == previous[key]) &&
        _coordinates.any((key) => state[key] != sent[key]);
  }

  static double _distanceSquared(
      Map<String, Object> a, Map<String, Object> b, String x, String y) {
    final dx = (a[x] as num).toDouble() - (b[x] as num).toDouble();
    final dy = (a[y] as num).toDouble() - (b[y] as num).toDouble();
    return dx * dx + dy * dy;
  }

  void attempted(int now) => _attemptAt = now;
  void acknowledged(Map<String, Object> state, int now) {
    _sent = state;
    _sentAt = now;
  }

  void reset() {
    _sent = _observed = null;
    _attemptAt = _sentAt = null;
  }
}
