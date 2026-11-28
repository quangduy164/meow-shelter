import 'package:material_ui/material_ui.dart';
import '../../fishing/fishing_controller.dart';
import '../../fishing/fishing_player.dart';
import '../../online/fishing_sticker.dart';
import '../../online/fishing_world.dart';
import '../design.dart';
import 'fishing_sticker_art.dart';

/// Only outdoor players share a coordinate space; cabin/parkour are separate scenes.
class FishingChatBubbles extends StatelessWidget {
  const FishingChatBubbles(
      {super.key,
      required this.controller,
      required this.world,
      required this.frames});
  final FishingController controller;
  final FishingWorld world;
  final Listenable frames;
  @override
  Widget build(BuildContext context) => IgnorePointer(
      child: AnimatedBuilder(
          animation: world.chat,
          builder: (context, _) {
            final river = controller.river, chat = world.chat;
            if (!chat.hasBubbles) return const SizedBox.shrink();
            return AnimatedBuilder(
                animation: frames,
                builder: (context, _) {
                  if (river.cabin.inside || river.cave.inside) {
                    return const SizedBox.shrink();
                  }
                  // Everyone outdoors: uid -> (world position, ashore, breed, local).
                  final cats = <String,
                      ({Offset position, bool land, String cat, bool local})>{};
                  if (chat.uid case final uid?) {
                    cats[uid] = (
                      position: controller.angler,
                      land: river.island.ashore,
                      cat: controller.player.cat,
                      local: true
                    );
                  }
                  for (final peer in world.peers.values) {
                    final location = peer.target.location;
                    if (location == FishingPlayerLocation.water ||
                        location == FishingPlayerLocation.land) {
                      cats[peer.uid] = (
                        position: peer.position,
                        land: location == FishingPlayerLocation.land,
                        cat: peer.target.cat,
                        local: false
                      );
                    }
                  }
                  double headY(
                          ({
                            Offset position,
                            bool land,
                            String cat,
                            bool local
                          }) c) =>
                      river.toScreen(c.position).dy -
                      (c.land ? 84 * .78 : 114 * .69) * river.scale -
                      (c.local ? 48 : 74);
                  bool offscreen(Offset p) =>
                      p.dx < -80 ||
                      p.dx > river.visibleWidth * river.scale + 80 ||
                      p.dy < -80 ||
                      p.dy > river.visibleHeight * river.scale + 120;

                  final bubbles = <Widget>[];
                  for (final MapEntry(key: uid, value: me) in cats.entries) {
                    final message = chat.bubble(uid);
                    if (message == null) continue;
                    final p = river.toScreen(me.position);
                    if (offscreen(p)) continue;
                    final sticker = FishingSticker.parse(message.text);
                    final friend =
                        sticker?.target == null ? null : cats[sticker!.target];
                    if (sticker != null && friend != null) {
                      // Two cats meeting, drawn above the middle of the pair.
                      final q = river.toScreen(friend.position);
                      final meLeft = p.dx <= q.dx;
                      const size = 64.0;
                      final mid = (p.dx + q.dx) / 2;
                      final top = (headY(me) < headY(friend)
                              ? headY(me)
                              : headY(friend)) -
                          14;
                      final mine = FishingSticker.interactSheet(sticker.breed),
                          theirs = FishingSticker.interactSheet(friend.cat);
                      bubbles.add(Positioned(
                          key: ValueKey(message.id),
                          left: mid - size,
                          top: top,
                          child: FishingInteractionArt(
                              animate: true,
                              index: sticker.index,
                              left: meLeft ? mine : theirs,
                              right: meLeft ? theirs : mine,
                              size: size)));
                      continue;
                    }
                    if (sticker != null) {
                      const size = 60.0;
                      bubbles.add(Positioned(
                          left: p.dx - size / 2,
                          top: headY(me) - 4,
                          child: sticker.interaction
                              ? FishingStickerArt(
                                  FishingSticker.interactSheet(sticker.breed),
                                  sticker.index,
                                  FishingSticker.interactions.length,
                                  size: size)
                              : FishingStickerArt(
                                  FishingSticker.emoteSheet(sticker.breed),
                                  sticker.index,
                                  FishingSticker.emoteCount,
                                  size: size)));
                      continue;
                    }
                    bubbles.add(Positioned(
                        left: p.dx - 30,
                        top: headY(me),
                        width: 60,
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 6),
                              child: Text(message.text,
                                  maxLines: 1,
                                  overflow: TextOverflow.clip,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: DS.ink,
                                      fontSize: 30,
                                      fontWeight: FontWeight.w600))),
                          const SizedBox(height: 3),
                        ])));
                  }
                  return Stack(clipBehavior: Clip.none, children: bubbles);
                });
          }));
}
