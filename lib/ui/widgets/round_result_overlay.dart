import 'game_pressable.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../design.dart';
import 'game_glyphs.dart';
import '../../game/components/hud_component.dart';
import '../../game/meow_shelter_game.dart';
import '../../game/constants.dart';
import '../../levels/levels.dart';

/// End-of-round card: cat portrait, headline, one star per mission with
/// its label underneath, and the next actions.
class RoundResultOverlay extends StatefulWidget {
  const RoundResultOverlay(
      {super.key,
      required this.game,
      required this.onHome,
      this.nextLabel = 'MÀN TIẾP'});
  final MeowShelterGame game;
  final VoidCallback onHome;
  final String nextLabel;

  @override
  State<RoundResultOverlay> createState() => _RoundResultOverlayState();
}

class _RoundResultOverlayState extends State<RoundResultOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _sprite;
  late final AnimationController _reveal;
  late final ui.Image _portrait;
  late final int _frameCount;

  MeowShelterGame get _game => widget.game;
  bool get _won => _game.roundStatus == RoundStatus.won;
  bool get _scored =>
      _won && !_game.level.isInfinite && !_game.level.isTutorial;

  @override
  void initState() {
    super.initState();
    final type = _game.level.bossType ?? _game.level.catTypes.first;
    final folder = '${type[0].toUpperCase()}${type.substring(1)}';
    _portrait = _game.images
        .fromCache('Cat/$folder/cat-$type-${_won ? 'celebrate' : 'idle'}.png');
    _frameCount = _portrait.width ~/ _portrait.height;
    _sprite = AnimationController(
        vsync: this,
        duration: Duration(
            milliseconds: (_frameCount * animationStepTime * 1000).round()))
      ..repeat();
    _reveal = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..forward();
  }

  @override
  void dispose() {
    _sprite.dispose();
    _reveal.dispose();
    super.dispose();
  }

  String get _header {
    final level = _game.level;
    if (level.isInfinite) return 'CỨU HỘ VÔ HẠN';
    if (level.isTutorial) return 'MÀN TẬP';
    return 'MÀN ${levelNumber(level) ?? ''} · ${level.name.toUpperCase()}';
  }

  String get _title {
    if (_game.level.isInfinite) return _game.lostReason;
    if (!_won) return _game.lostReason;
    return _game.level.isTutorial ? 'GIỎI LẮM!' : 'VỀ NHÀ RỒI!';
  }

  String get _subtitle {
    final level = _game.level;
    final rescued = _game.rescued;
    if (level.isInfinite) return 'Cứu được $rescued mèo · +${rescued * 5} xu';
    if (level.isTutorial) return 'Bạn đã biết cách bắt mèo này rồi';
    if (_won) return 'Cứu đủ $rescued mèo · +${rescued * 5} xu';
    return 'Đã cứu $rescued/${level.catTypes.length} mèo · thử lại nhé!';
  }

  @override
  Widget build(BuildContext context) {
    final next = _won && _game.onNextLevel != null;
    return BlockSemantics(
      child: Stack(fit: StackFit.expand, children: [
        const ModalBarrier(dismissible: false, color: DS.scrim),
        SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(DS.spaceLg),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: .9, end: 1),
                  duration: DS.overlayDuration,
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: Material(
                    color: Colors.transparent,
                    child: Stack(clipBehavior: Clip.none, children: [
                      Container(
                        width: 470,
                        padding: const EdgeInsets.fromLTRB(
                            DS.spaceLg, 26, DS.spaceLg, DS.spaceLg),
                        decoration: DS.card.copyWith(color: DS.cream),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          Row(children: [
                            _Portrait(
                                image: _portrait,
                                frames: _frameCount,
                                animation: _sprite,
                                won: _won),
                            const SizedBox(width: DS.spaceLg),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Semantics(
                                      liveRegion: true,
                                      child: Text(_title,
                                          style: TextStyle(
                                              fontSize: DS.fontTitle,
                                              height: 1.1,
                                              fontWeight: FontWeight.w900,
                                              color:
                                                  _won ? DS.ink : DS.danger)),
                                    ),
                                    const SizedBox(height: DS.spaceXs),
                                    Text(_subtitle,
                                        style: const TextStyle(
                                            fontSize: DS.fontBody,
                                            fontWeight: FontWeight.w700,
                                            color: DS.soft)),
                                  ]),
                            ),
                          ]),
                          if (_scored) ...[
                            const SizedBox(height: DS.spaceMd),
                            _StarRow(game: _game, reveal: _reveal),
                          ],
                          const SizedBox(height: DS.spaceMd),
                          Row(children: [
                            _ActionButton(
                                tooltip: 'Về chọn màn',
                                icon: Icons.home_rounded,
                                glyph: GameGlyph.home,
                                onPressed: widget.onHome),
                            const SizedBox(width: DS.spaceSm),
                            if (next) ...[
                              _ActionButton(
                                  tooltip: 'Chơi lại',
                                  icon: Icons.replay_rounded,
                                  onPressed: _game.restartRound),
                              const SizedBox(width: DS.spaceSm),
                            ],
                            Expanded(
                              child: _ActionButton(
                                  tooltip: next ? widget.nextLabel : 'Chơi lại',
                                  icon: next
                                      ? Icons.arrow_forward_rounded
                                      : Icons.replay_rounded,
                                  label: next ? widget.nextLabel : 'CHƠI LẠI',
                                  primary: true,
                                  onPressed: next
                                      ? _game.onNextLevel!
                                      : _game.restartRound),
                            ),
                          ]),
                        ]),
                      ),
                      Positioned(
                        top: -14,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: DS.spaceLg, vertical: DS.spaceXs),
                            decoration: BoxDecoration(
                                color: DS.gold,
                                borderRadius:
                                    BorderRadius.circular(DS.radiusControl),
                                border:
                                    Border.all(color: DS.goldEdge, width: 2),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Color(0x44000000),
                                      blurRadius: 4,
                                      offset: Offset(0, 2))
                                ]),
                            child: Text(_header,
                                style: const TextStyle(
                                    color: DS.ink,
                                    fontSize: DS.fontCaption,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1)),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Round avatar with the cat's celebrate (won) or idle (lost) animation.
class _Portrait extends StatelessWidget {
  const _Portrait(
      {required this.image,
      required this.frames,
      required this.animation,
      required this.won});
  final ui.Image image;
  final int frames;
  final Animation<double> animation;
  final bool won;

  @override
  Widget build(BuildContext context) => Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
              colors: won
                  ? const [Color(0xFFFFF0C8), Color(0xFFFFD98A)]
                  : const [Color(0xFFF0E6D6), DS.mutedFill]),
          border: Border.all(color: DS.wood, width: 3),
        ),
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) => CustomPaint(
            painter: _ResultCat(image,
                math.min(frames - 1, (animation.value * frames).floor())),
          ),
        ),
      );
}

/// Three medals: "finished" plus one per level goal, popping in one by one.
class _StarRow extends StatelessWidget {
  const _StarRow({required this.game, required this.reveal});
  final MeowShelterGame game;
  final Animation<double> reveal;

  @override
  Widget build(BuildContext context) {
    final entries = [
      ('Hoàn thành màn', true),
      for (final goal in game.level.goals) (goal.label, goal.met(game.stats)),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: DS.spaceSm, horizontal: DS.spaceXs),
      decoration: BoxDecoration(
          color: DS.surfaceRaised,
          borderRadius: BorderRadius.circular(DS.radiusLg),
          border: Border.all(color: DS.borderMedium, width: 1.5)),
      child: Row(children: [
        for (var i = 0; i < entries.length; i++)
          Expanded(
            child: AnimatedBuilder(
              animation: reveal,
              builder: (context, _) {
                final start = .1 + i * .22;
                final t = ((reveal.value - start) / .35).clamp(0.0, 1.0);
                final earned = entries[i].$2;
                final scale = earned ? Curves.elasticOut.transform(t) : t;
                return Column(children: [
                  Transform.scale(
                    scale: .4 + scale * .6,
                    child: Opacity(
                      opacity: t,
                      child: Icon(Icons.star_rounded,
                          size: 40,
                          color: earned ? DS.star : const Color(0x55704019),
                          shadows: earned
                              ? const [
                                  Shadow(
                                      color: DS.goldEdge, offset: Offset(0, 2))
                                ]
                              : null),
                    ),
                  ),
                  const SizedBox(height: DS.space2),
                  Text(entries[i].$1,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(
                          fontSize: DS.fontCaption,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          color: earned ? DS.ink : DS.mutedText)),
                ]);
              },
            ),
          ),
      ]),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton(
      {required this.tooltip,
      required this.icon,
      required this.onPressed,
      this.label,
      this.glyph,
      this.primary = false});
  final String tooltip;
  final IconData icon;
  final GameGlyph? glyph;
  final VoidCallback onPressed;
  final String? label;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final edge = primary ? DS.goldEdge : DS.wood;
    return GamePressable(
      height: DS.controlHeight,
      width: label == null ? DS.touchTarget : null,
      color: primary ? DS.gold : DS.cream,
      shade: edge,
      radius: DS.radiusControl,
      depth: DS.buttonDepth,
      gradient: false,
      tooltip: tooltip,
      onPressed: onPressed,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        glyph != null
            ? GameGlyphView(glyph!, size: DS.iconLg)
            : Icon(icon, size: DS.iconMd, color: DS.ink),
        if (label != null) ...[
          const SizedBox(width: DS.spaceSm),
          Text(label!, style: DS.buttonText.copyWith(color: DS.ink)),
        ],
      ]),
    );
  }
}

class _ResultCat extends CustomPainter {
  const _ResultCat(this.image, this.frame);
  final ui.Image image;
  final int frame;
  @override
  void paint(Canvas canvas, Size size) {
    final frameSize = image.height.toDouble();
    final side = size.shortestSide * .92;
    canvas.drawImageRect(
        image,
        Rect.fromLTWH(frame * frameSize, 0, frameSize, frameSize),
        Rect.fromCenter(
            center: size.center(const Offset(0, -2)),
            width: side,
            height: side),
        Paint()..filterQuality = FilterQuality.medium);
  }

  @override
  bool shouldRepaint(covariant _ResultCat oldDelegate) =>
      image != oldDelegate.image || frame != oldDelegate.frame;
}
