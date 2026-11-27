import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import '../../fishing/fishing_controller.dart';
import '../../fishing/fishing_river.dart';
import '../../fishing/fishing_boat.dart';
import '../../fishing/fishing_rod.dart';
import '../../fishing/fishing_player.dart';
import '../../game/constants.dart';
import 'cat_sprite.dart';
import 'fishing_painter.dart';
import 'fishing_fish_art.dart';
import 'fishing_river_scene.dart';

/// Local cat, seated companions, rod/line and catch artwork in screen space.
/// The parent supplies frame-driven rebuilding; this layer owns no tickers.
class FishingPlayerLayer extends StatelessWidget {
  const FishingPlayerLayer({super.key, required FishingController controller})
      : _controller = controller;
  final FishingController _controller;
  FishingRiverRound get _river => _controller.river;
  String get _cat => _controller.player.cat;

  @override
  Widget build(BuildContext context) =>
      Stack(fit: StackFit.expand, children: [_boat(), _islandCat()]);

  Widget _boat() {
    final point = _river.toScreen(_controller.angler);
    final catSize = (_river.island.ashore ? 84 : 114) * _river.scale;
    final phase = _controller.phase;
    final won = phase == FishingPhase.caught;
    final fishing = _controller.showFishingArt;
    final facingRight = fishing
        ? _controller.spot.dx >= _controller.angler.dx
        : _controller.player.facingRight;
    // Where the lantern rod's lantern hangs, for its glow in the dark.
    final f = _river.island.ashore ? .74 : 1.0;
    _river.rodLantern = fishing && !won && _controller.rod == FishingRod.lantern
        ? _controller.angler + Offset((facingRight ? 1 : -1) * 80, -62) * f
        : null;
    // The sheets animate casting, reeling and rowing; only the bite shakes.
    final lean = phase == FishingPhase.bite
        ? math.sin(_controller.clock * 20) * .035
        : 0.0;
    // The swan is pedalled: no oar, the cat bobs gently with each push.
    final pedalling = _river.localDrives &&
        _river.boatStyle == FishingBoat.swan &&
        _river.moving &&
        !fishing;
    final pedalBob = pedalling
        ? -math.sin(_river.clock * 9).abs() * 2.2 * _river.scale
        : 0.0;
    // The idle sheet sits lower than the row/fish sheets; on the swan's
    // raised seat lift it so the cat shows above the side like the others.
    double swanSeatLift(String action) =>
        _river.boatStyle == FishingBoat.swan && action == 'idle'
            ? 10 * _river.scale
            : 0;
    final (action, frames, frame) = _controller.player.pose;
    final driverFishing = _river.localDrives
        ? fishing
        : (_river.crew.driver?.pose.$1.startsWith('fish-') ?? false);
    final bob = math.sin(_river.clock * 2.5) * 1.8 * _river.scale;
    return Stack(fit: StackFit.expand, children: [
      CustomPaint(
          painter: FishingRiverBoatPainter(_river, fishing: driverFishing)),
      // Every other occupied seat, including a remote driver.
      for (final member in _river.crew.seats.whereType<FishingPlayerState>())
        if (member.id != _controller.player.id)
          Builder(builder: (context) {
            final p = _river.toScreen(_river.playerPosition(member));
            final pose = member.pose;
            final riderSize = 114 * _river.scale;
            return Positioned(
                left: p.dx - riderSize / 2,
                top: p.dy - riderSize * .69 + bob - swanSeatLift(pose.$1),
                child: CatSprite(
                    type: member.cat,
                    size: riderSize,
                    action: pose.$1,
                    frames: pose.$2,
                    frame: pose.$3,
                    flip: !member.facingRight));
          }),
      if (!_river.island.ashore)
        Positioned(
            left: point.dx - catSize / 2,
            top: point.dy -
                catSize * .69 +
                math.sin(_river.clock * 2.5) * 1.8 * _river.scale +
                pedalBob -
                swanSeatLift(action),
            child: Transform.rotate(
              angle: lean,
              alignment: Alignment.bottomCenter,
              child: CatSprite(
                  type: _cat,
                  size: catSize,
                  action: action,
                  frames: frames,
                  frame: frame,
                  flip: !facingRight),
            )),
      CustomPaint(
          painter: FishingRiverBoatPainter(_river,
              front: true, fishing: driverFishing)),
      if (fishing && !won)
        Builder(builder: (context) {
          final spot = _river.toScreen(_controller.spot);
          return CustomPaint(
              painter: FishingPainter(
            rod: _controller.rod,
            phase: phase,
            fish: _controller.fish,
            boat: Offset(point.dx / _river.viewport.width,
                point.dy / _river.viewport.height),
            spot: Offset(spot.dx / _river.viewport.width,
                spot.dy / _river.viewport.height),
            facingRight: facingRight,
            artScale: _river.scale * (_river.island.ashore ? .74 : 1),
            clock: _controller.clock,
            elapsed: _controller.elapsed,
            progress: _controller.progress,
            tension: _controller.tension,
            pulling: _controller.pulling,
            drift: _controller.drift,
            sweetCenter: _controller.sweetCenter,
            combo: _controller.combo,
          ));
        }),
      if (won)
        Builder(builder: (context) {
          // The catch flies into the cupped paws, then rides along with them.
          final t =
              Curves.easeInOut.transform(_controller.elapsed.clamp(0.0, 1.0));
          final paws = _anglerSheetPoint(fishHoldPaws[_holdFrame]);
          final position =
              Offset.lerp(_river.toScreen(_controller.spot), paws, t)! -
                  Offset(0, math.sin(t * math.pi) * 45);
          final fishSize = _controller.fishScale;
          return Positioned(
              left: position.dx - 20 * fishSize,
              top: position.dy - 14 * fishSize,
              child: SizedBox(
                  width: 40 * fishSize,
                  height: 28 * fishSize,
                  child:
                      CustomPaint(painter: FishingFishArt(_controller.fish))));
        }),
    ]);
  }

  int get _holdFrame => _controller.holdFrame;

  /// Screen position of a point given in sheet pixels (256 x 256 frame,
  /// facing right) of the angler sprite, in the boat or on the bank.
  Offset _anglerSheetPoint((double, double) sheet) {
    final island = _river.island;
    final ashore = island.ashore;
    final point = _river.toScreen(_controller.angler);
    final size = (ashore ? 84 : 114) * _river.scale;
    final flip = _controller.spot.dx < _controller.angler.dx;
    final top = ashore
        ? point.dy - size * .78
        : point.dy -
            size * .69 +
            math.sin(_river.clock * 2.5) * 1.8 * _river.scale;
    final x = flip ? 256 - sheet.$1 : sheet.$1;
    return Offset(
        point.dx - size / 2 + x / 256 * size, top + sheet.$2 / 256 * size);
  }

  Widget _islandCat() {
    final island = _river.island;
    if (!island.ashore) return const SizedBox.shrink();
    final point = _river.toScreen(island.cat);
    final fishing = _controller.showFishingArt;
    final size = 84 * _river.scale;
    final hopping = island.hopProgress != null;
    final (action, frames, frame) = _controller.player.pose;
    // The jump sheet already lifts the cat in its air frames.
    final sheetLift = hopping ? jumpSheetLift[frame] * size : 0.0;
    return Stack(children: [
      if (!island.lookout)
        Positioned(
            left: point.dx - 14 * _river.scale,
            top: point.dy - 3 * _river.scale,
            child: Container(
                width: 28 * _river.scale,
                height: 10 * _river.scale,
                decoration: const BoxDecoration(
                    color: Color(0x3359553B), shape: BoxShape.circle))),
      Positioned(
          left: point.dx - size / 2,
          top: point.dy - size * .78 - island.jump * _river.scale + sheetLift,
          child: CatSprite(
              type: _cat,
              size: size,
              action: action,
              frames: frames,
              frame: frame,
              flip: fishing
                  ? _controller.spot.dx < island.cat.dx
                  : !island.facingRight)),
    ]);
  }
}
