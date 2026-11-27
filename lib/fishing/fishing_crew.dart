import 'fishing_boat.dart';
import 'fishing_player.dart';

/// Who sits where on the current boat. Seat 0 is the driver's seat: the
/// first one aboard drives, and when the driver leaves the next passenger
/// takes the helm. Only the driver rows and steers; passengers can still
/// fish.
///
/// Offline the local player boards first; the crew has no special local ID.
class FishingCrew {
  FishingCrew({required this.boatId, FishingBoat boat = FishingBoat.basket})
      : _seats = List.filled(boat.seats, null);

  final String boatId;
  List<FishingPlayerState?> _seats;

  int get seatCount => _seats.length;
  FishingPlayerState? get driver => _seats.first;
  List<FishingPlayerState?> get seats => List.unmodifiable(_seats);

  /// Everyone except the driver, with their seat index.
  Iterable<(int, FishingPlayerState)> get passengers sync* {
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
  int? board(FishingPlayerState member) {
    final already = seatOf(member.id);
    if (already != null) return already;
    if (member.boatId != null && member.boatId != boatId) return null;
    final free = _seats.indexOf(null);
    if (free < 0) return null;
    _seats[free] = member;
    member.assignSeat(boatId, free);
    return free;
  }

  /// [id] gets off; if they were driving, passengers move up one seat so
  /// the earliest passenger becomes the driver.
  void leave(String id) {
    final seat = seatOf(id);
    if (seat == null) return;
    _seats[seat]!.assignSeat(null, null);
    _seats[seat] = null;
    if (seat == 0) {
      final rest = _seats.whereType<FishingPlayerState>().toList();
      _seats = List.filled(_seats.length, null);
      for (var i = 0; i < rest.length; i++) {
        _seats[i] = rest[i];
        rest[i].assignSeat(boatId, i);
      }
    }
  }

  /// Switching boats keeps the boarding order; anyone who no longer fits
  /// is returned so the caller can put them ashore.
  List<FishingPlayerState> refit(FishingBoat boat) {
    final aboard = _seats.whereType<FishingPlayerState>().toList();
    _seats = List.filled(boat.seats, null);
    for (var i = 0; i < aboard.length && i < _seats.length; i++) {
      _seats[i] = aboard[i];
      aboard[i].assignSeat(boatId, i);
    }
    final displaced = aboard.skip(_seats.length).toList();
    for (final player in displaced) {
      player.assignSeat(null, null);
    }
    return displaced;
  }
}
