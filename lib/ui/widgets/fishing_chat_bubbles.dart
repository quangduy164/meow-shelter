import 'package:material_ui/material_ui.dart';
import '../../fishing/fishing_controller.dart';
import '../../fishing/fishing_player.dart';
import '../../online/fishing_chat.dart';
import '../../online/fishing_world.dart';
import '../design.dart';

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
                  final bubbles = <Widget>[];
                  void add(
                      FishingChatMessage? message, Offset position, bool land,
                      {bool local = false}) {
                    if (message == null) return;
                    final p = river.toScreen(position);
                    if (p.dx < -80 ||
                        p.dx > river.visibleWidth * river.scale + 80 ||
                        p.dy < -80 ||
                        p.dy > river.visibleHeight * river.scale + 120) {
                      return;
                    }
                    bubbles.add(Positioned(
                        left: p.dx - 30,
                        top: p.dy -
                            (land ? 84 * .78 : 114 * .69) * river.scale -
                            (local ? 48 : 74),
                        width: 60,
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 6),
                              decoration: BoxDecoration(
                                  color: DS.cream,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFFD8CEB8))),
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

                  if (chat.uid case final uid?) {
                    add(chat.bubble(uid), controller.angler,
                        river.island.ashore,
                        local: true);
                  }
                  for (final peer in world.peers.values) {
                    final location = peer.target.location;
                    if (location == FishingPlayerLocation.water ||
                        location == FishingPlayerLocation.land) {
                      add(chat.bubble(peer.uid), peer.position,
                          location == FishingPlayerLocation.land);
                    }
                  }
                  return Stack(clipBehavior: Clip.none, children: bubbles);
                });
          }));
}
