import 'package:flutter/painting.dart';

import '../game/cats/cat_breed.dart';

/// Locations have different coordinate spaces; cabin/parkour positions must
/// never be interpreted as positions on the outdoor map.
enum FishingPlayerLocation { water, land, cabin, bedroom, parkour }

typedef FishingPlayerPose = (String action, int frames, int frame);

/// One player's visible state. It owns no inventory, rewards or networking.
/// Boat membership is maintained by FishingCrew, including seat promotion.
class FishingPlayerState {
  FishingPlayerState({required this.id, String cat = 'orange'})
      : cat = CatBreed.of(cat).id;

  final String id;
  String cat;
  Offset position = Offset.zero;
  bool facingRight = true;
  FishingPlayerLocation location = FishingPlayerLocation.water;
  FishingPlayerPose pose = ('idle', 6, 0);
  String? _boatId;
  int? _seat;
  String? get boatId => _boatId;
  int? get seat => _seat;

  void assignSeat(String? boatId, int? seat) {
    assert((boatId == null) == (seat == null));
    assert(seat == null || seat >= 0);
    _boatId = boatId;
    _seat = seat;
  }
}
