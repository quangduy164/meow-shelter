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
      {super.key, required this.game, required this.onHome});
  final MeowShelterGame game;
  final VoidCallback onHome;

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
    if (_game.level.isInfinite) return 'MÈO ĐÃ CHẠY MẤT!';
    if (!_won) return _game.lostReason;
    return _game.level.isTutorial ? 'GIỎI LẮM!' : 'VỀ NHÀ RỒI!';
  }

  String get _subtitle {
    final level = _game.level;
    final rescued = _game.rescued;
    if (level.isInfinite) return 'Cứu được $rescued bé · +${rescued * 5} xu';
    if (level.isTutorial) return 'Bạn đã biết cách bắt bé này rồi';
    if (_won) return 'Cứu đủ $rescued bé · +${rescued * 5} xu';
    return 'Đã cứu $rescued/${level.catTypes.length} bé · thử lại nhé!';
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
              padding: const EdgeInsets.all(16),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: .9, end: 1),
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: Material(
                    color: Colors.transparent,
                    child: Stack(clipBehavior: Clip.none, children: [
                      Container(
                        width: 470,
                        padding: const EdgeInsets.fromLTRB(20, 26, 20, 16),
                        decoration: DS.card.copyWith(color: DS.cream),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          Row(children: [
                            _Portrait(
                                image: _portrait,
                                frames: _frameCount,
                                animation: _sprite,
                                won: _won),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Semantics(
                                      liveRegion: true,
                                      child: Text(_title,
                                          style: TextStyle(
                                              fontSize: 27,
                                              height: 1.1,
                                              fontWeight: FontWeight.w900,
                                              color: _won
                                                  ? DS.ink
                                                  : const Color(0xFFB0503A))),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(_subtitle,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: DS.soft)),
                                  ]),
                            ),
                          ]),
                          if (_scored) ...[
                            const SizedBox(height: 12),
                            _StarRow(game: _game, reveal: _reveal),
                          ],
                          const SizedBox(height: 14),
                          Row(children: [
                            _ActionButton(
                                tooltip: 'Về chọn màn',
                                icon: Icons.home_rounded,
                                glyph: GameGlyph.back,
                                onPressed: widget.onHome),
                            const SizedBox(width: 10),
                            if (next) ...[
                              _ActionButton(
                                  tooltip: 'Chơi lại',
                                  icon: Icons.replay_rounded,
                                  onPressed: _game.restartRound),
                              const SizedBox(width: 10),
                            ],
                            Expanded(
                              child: _ActionButton(
                                  tooltip: next ? 'Màn tiếp' : 'Chơi lại',
                                  icon: next
                                      ? Icons.arrow_forward_rounded
                                      : Icons.replay_rounded,
                                  label: next ? 'MÀN TIẾP' : 'CHƠI LẠI',
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
                                horizontal: 16, vertical: 5),
                            decoration: BoxDecoration(
                                color: DS.gold,
                                borderRadius: BorderRadius.circular(14),
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
                                    fontSize: 12.5,
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
                  : const [Color(0xFFF0E6D6), Color(0xFFD9CDB8)]),
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
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
          color: const Color(0xFFFFFBEF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x99B27A3E), width: 1.5)),
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
                  const SizedBox(height: 2),
                  Text(entries[i].$1,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(
                          fontSize: 11,
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
    return Tooltip(
      message: tooltip,
      child: Container(
        height: 46,
        width: label == null ? 46 : null,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: edge, offset: const Offset(0, 4))]),
        child: Material(
          color: primary ? DS.gold : DS.cream,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: edge, width: 2)),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(14),
            child: Semantics(
              button: true,
              label: tooltip,
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                glyph != null
                    ? GameGlyphView(glyph!, size: 26)
                    : Icon(icon, size: 23, color: DS.ink),
                if (label != null) ...[
                  const SizedBox(width: 7),
                  Text(label!,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: DS.ink)),
                ],
              ]),
            ),
          ),
        ),
      ),
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
