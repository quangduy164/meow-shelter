/// Ignore the initial roster and brief reconnects; movement never announces joins.
class FishingArrivals {
  bool _ready = false;
  Set<String> _present = {};
  final Map<String, int> _lastSeen = {};

  List<String> update(Iterable<String> ids, int now) {
    final next = ids.toSet();
    final joined = <String>[];
    for (final id in next) {
      if (_ready &&
          !_present.contains(id) &&
          (!_lastSeen.containsKey(id) || now - _lastSeen[id]! > 10000)) {
        joined.add(id);
      }
      _lastSeen[id] = now;
    }
    _lastSeen
        .removeWhere((id, seen) => !next.contains(id) && now - seen > 10000);
    _present = next;
    _ready = true;
    return joined;
  }

  void reset() {
    _ready = false;
    _present.clear();
    _lastSeen.clear();
  }
}
