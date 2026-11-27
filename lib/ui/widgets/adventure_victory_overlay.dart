import 'package:material_ui/material_ui.dart';
import '../../game/adventure/adventure_game.dart';
import '../../game/adventure/adventure_hud.dart';
import '../design.dart';
import 'cat_sprite.dart';
import 'game_glyphs.dart';
import 'game_surfaces.dart';

class AdventureVictoryOverlay extends StatelessWidget {
  const AdventureVictoryOverlay(
      {super.key, required this.game, required this.onReplay});
  final AdventureGame game;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    final seconds = game.elapsed.floor();
    final time = '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
        '${(seconds % 60).toString().padLeft(2, '0')}';
    return Material(
      color: DS.scrim,
      child: SafeArea(
          child: Center(
              child: Padding(
        padding: const EdgeInsets.all(DS.spaceLg),
        child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Container(
              width: 440,
              padding: const EdgeInsets.fromLTRB(
                  DS.spaceXl, DS.spaceLg, DS.spaceXl, DS.spaceLg),
              decoration: DS.card,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('CHIẾN THẮNG!',
                    style: TextStyle(
                        color: DS.ink,
                        fontSize: DS.fontTitle,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .6)),
                const SizedBox(height: DS.spaceXs),
                const Text('Mèo đã về nhà an toàn',
                    style: TextStyle(color: DS.soft, fontSize: DS.fontBody)),
                const SizedBox(height: DS.spaceSm),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  CatSprite(type: game.selectedCat, size: 70),
                  const SizedBox(width: DS.spaceSm),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    for (var i = 0; i < 3; i++)
                      Icon(
                          i < game.stars
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 38,
                          color: i < game.stars ? DS.goldEdge : DS.mutedBorder),
                  ]),
                ]),
                const SizedBox(height: DS.spaceSm),
                Row(children: [
                  Expanded(
                      child: _stat(
                          const Icon(Icons.timer_outlined,
                              color: DS.label, size: 20),
                          'Thời gian',
                          time)),
                  const SizedBox(width: DS.spaceSm),
                  Expanded(
                      child: _stat(
                          const SizedBox.square(
                              dimension: 24,
                              child:
                                  CustomPaint(painter: _VictoryFishPainter())),
                          'Cá thu thập',
                          '${game.fish}')),
                ]),
                const SizedBox(height: DS.spaceSm),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: DS.spaceMd, vertical: DS.spaceSm),
                  decoration: BoxDecoration(
                    color: DS.gold.withValues(alpha: .4),
                    borderRadius: BorderRadius.circular(DS.radiusMd),
                    border: Border.all(color: DS.goldEdge),
                  ),
                  child: Row(children: [
                    const Icon(Icons.monetization_on_rounded,
                        color: DS.goldEdge, size: 22),
                    const SizedBox(width: DS.spaceSm),
                    const Expanded(
                        child: Text('Xu nhận được',
                            style: TextStyle(
                                color: DS.ink,
                                fontSize: DS.fontBody,
                                fontWeight: FontWeight.w800))),
                    Text('+${game.reward} xu',
                        style: const TextStyle(
                            color: DS.ink,
                            fontSize: DS.fontDisplay,
                            fontWeight: FontWeight.w900)),
                  ]),
                ),
                const SizedBox(height: DS.spaceMd),
                Row(children: [
                  Expanded(
                      child: ElevatedButton.icon(
                    style: DS.secondary,
                    onPressed: onReplay,
                    icon: const Icon(Icons.replay_rounded, size: 20),
                    label: const Text('Chơi lại',
                        style: TextStyle(
                            fontFamily: 'Roboto', fontSize: DS.fontButton)),
                  )),
                  const SizedBox(width: DS.spaceSm),
                  Expanded(
                      child: ElevatedButton.icon(
                    style: DS.primary,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const GameGlyphView(GameGlyph.home, size: 20),
                    label: const Text('Trang chủ',
                        style: TextStyle(
                            fontFamily: 'Roboto', fontSize: DS.fontButton)),
                  )),
                ]),
              ]),
            )),
      ))),
    );
  }

  Widget _stat(Widget icon, String label, String value) =>
      GameStat(icon: icon, label: label, value: value);
}

class _VictoryFishPainter extends CustomPainter {
  const _VictoryFishPainter();

  @override
  void paint(Canvas canvas, Size size) =>
      paintAdventureFishIcon(canvas, size.center(Offset.zero));

  @override
  bool shouldRepaint(covariant _VictoryFishPainter oldDelegate) => false;
}
