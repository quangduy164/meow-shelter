import 'fishing_boat.dart';

/// Someone riding the boat: the local player or (later) an online friend.
/// [cat] is the CatSprite type drawn in their seat.
class FishingCrewMember {
  const FishingCrewMember(this.id, {this.cat = 'orange'});
  final String id;
  final String cat;
}

/// Who sits where on the current boat. Seat 0 is the driver's seat: the
/// first one aboard drives, and when the driver leaves the next passenger
/// takes the helm. Only the driver rows and steers; passengers can still
/// fish.
///
/// Offline there is only [localId], always the driver, so play is
/// unchanged. Online code only needs to call [board] / [leave] for remote
/// players and draw [passengers].
class FishingCrew {
  FishingCrew({FishingBoat boat = FishingBoat.basket})
      : _seats = List.filled(boat.seats, null) {
    board(const FishingCrewMember(localId));
  }

  static const localId = 'local';
  List<FishingCrewMember?> _seats;

  int get seatCount => _seats.length;
  FishingCrewMember? get driver => _seats.first;
  List<FishingCrewMember?> get seats => List.unmodifiable(_seats);

  /// Everyone except the driver, with their seat index.
  Iterable<(int, FishingCrewMember)> get passengers sync* {
    for (var i = 1; i < _seats.length; i++) {
      final m = _seats[i];
      if (m != null) yield (i, m);
    }
  }

  int? seatOf(String id) {
    final i = _seats.indexWhere((m) => m?.id == id);
    return i < 0 ? null : i;
  }

  bool canSteer(String id) => driver?.id == id;
  bool get hasFreeSeat => _seats.contains(null);

  /// Seats [member] in the first free seat (the helm if it is empty).
  /// Returns the seat, or null when the boat is full.
  int? board(FishingCrewMember member) {
    final already = seatOf(member.id);
    if (already != null) return already;
    final free = _seats.indexOf(null);
    if (free < 0) return null;
    _seats[free] = member;
    return free;
  }

  /// [id] gets off; if they were driving, passengers move up one seat so
  /// the earliest passenger becomes the driver.
  void leave(String id) {
    final seat = seatOf(id);
    if (seat == null) return;
    _seats[seat] = null;
    if (seat == 0) {
      final rest = _seats.whereType<FishingCrewMember>().toList();
      _seats = List.filled(_seats.length, null);
      for (var i = 0; i < rest.length; i++) {
        _seats[i] = rest[i];
      }
    }
  }

  /// Switching boats keeps the boarding order; anyone who no longer fits
  /// is returned so the caller can put them ashore.
  List<FishingCrewMember> refit(FishingBoat boat) {
    final aboard = _seats.whereType<FishingCrewMember>().toList();
    _seats = List.filled(boat.seats, null);
    for (var i = 0; i < aboard.length && i < _seats.length; i++) {
      _seats[i] = aboard[i];
    }
    return aboard.skip(_seats.length).toList();
  }
}
