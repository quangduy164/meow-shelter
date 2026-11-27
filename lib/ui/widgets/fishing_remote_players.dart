import 'package:material_ui/material_ui.dart';

import '../../fishing/fishing_boat.dart';
import '../../fishing/fishing_player.dart';
import '../../fishing/fishing_river.dart';
import '../../online/fishing_peer.dart';
import 'cat_sprite.dart';
import 'fishing_boats.dart';

/// Peers are display-only and never take part in local collision/rewards.
class FishingRemotePlayers extends StatelessWidget {
  const FishingRemotePlayers(
      {super.key, required this.round, required this.peers});
  final FishingRiverRound round;
  final Iterable<FishingPeer> peers;
  @override
  Widget build(BuildContext context) {
    final scale = round.scale;
    final view = Rect.fromLTWH(round.cameraLeft, round.cameraTop,
            round.visibleWidth, round.visibleHeight)
        .inflate(180);
    return IgnorePointer(
        child: Stack(clipBehavior: Clip.none, children: [
      for (final peer in peers) ...[
        if (view.contains(peer.boatPosition)) _boat(peer, false, scale),
        if ((peer.target.location == FishingPlayerLocation.water ||
                peer.target.location == FishingPlayerLocation.land) &&
            view.contains(peer.position))
          _cat(peer, scale),
        if (view.contains(peer.boatPosition)) _boat(peer, true, scale),
        if ((peer.target.location == FishingPlayerLocation.water ||
                peer.target.location == FishingPlayerLocation.land) &&
            view.contains(peer.position))
          _name(peer, scale),
      ],
    ]));
  }

  Widget _cat(FishingPeer peer, double scale) {
    final p = round.toScreen(peer.position);
    final land = peer.target.location == FishingPlayerLocation.land;
    final size = (land ? 84 : 114) * scale;
    final pose = peer.pose;
    final lift =
        !land && peer.target.boat == FishingBoat.swan && pose.$1 == 'idle'
            ? 10 * scale
            : 0.0;
    return Positioned(
        left: p.dx - size / 2,
        top: p.dy - size * (land ? .78 : .69) - lift,
        child: CatSprite(
            key: ValueKey('peer-cat:${peer.uid}'),
            type: peer.target.cat,
            size: size,
            action: pose.$1,
            frames: pose.$2,
            frame: pose.$3,
            flip: !peer.target.facingRight));
  }

  Widget _name(FishingPeer peer, double scale) {
    final p = round.toScreen(peer.position);
    final land = peer.target.location == FishingPlayerLocation.land;
    final lift = !land &&
            peer.target.boat == FishingBoat.swan &&
            peer.target.pose.$1 == 'idle'
        ? 10 * scale
        : 0.0;
    return Positioned(
        left: p.dx - 75,
        top: p.dy - (land ? 84 * .78 : 114 * .69) * scale - lift - 24,
        width: 150,
        child: Center(
            child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: const Color(0xAA24373D),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(peer.target.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)))));
  }

  Widget _boat(FishingPeer peer, bool front, double scale) {
    final p = round.toScreen(peer.boatPosition);
    return Positioned(
        left: p.dx - 110 * scale,
        top: p.dy - 100 * scale,
        width: 220 * scale,
        height: 160 * scale,
        child: CustomPaint(
            painter: _RemoteBoat(
                peer.target.boat, peer.target.boatRight, scale, front)));
  }
}

class _RemoteBoat extends CustomPainter {
  _RemoteBoat(this.boat, this.right, this.scale, this.front);
  final FishingBoat boat;
  final bool right, front;
  final double scale;
  @override
  void paint(Canvas c, Size size) {
    c.translate(110 * scale, 100 * scale);
    c.scale(scale);
    if (front) {
      paintBoatFront(c, boat, facingRight: right);
    } else {
      paintBoatBack(c, boat, facingRight: right);
    }
  }

  @override
  bool shouldRepaint(_RemoteBoat old) =>
      old.boat != boat ||
      old.right != right ||
      old.scale != scale ||
      old.front != front;
}
