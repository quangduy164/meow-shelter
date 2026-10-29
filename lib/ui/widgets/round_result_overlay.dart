import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../game/components/hud_component.dart';
import '../../game/meow_shelter_game.dart';
import '../../game/constants.dart';

class RoundResultOverlay extends StatefulWidget {
  const RoundResultOverlay(
      {super.key, required this.game, required this.onHome});
  final MeowShelterGame game;
  final VoidCallback onHome;

  @override
  State<RoundResultOverlay> createState() => _RoundResultOverlayState();
}

class _RoundResultOverlayState extends State<RoundResultOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;
  late final ui.Image _portrait;
  late final int _frameCount;
  bool get _won => widget.game.roundStatus == RoundStatus.won;

  @override
  void initState() {
    super.initState();
    final type = widget.game.level.catTypes.first;
    final folder = '${type[0].toUpperCase()}${type.substring(1)}';
    _portrait = widget.game.images
        .fromCache('Cat/$folder/cat-$type-${_won ? 'celebrate' : 'idle'}.png');
    _frameCount = _portrait.width ~/ _portrait.height;
    _animation = AnimationController(
        vsync: this,
        duration: Duration(
            milliseconds: (_frameCount * animationStepTime * 1000).round()))
      ..repeat();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final next = _won && widget.game.onNextLevel != null;
    return BlockSemantics(
      child: Stack(fit: StackFit.expand, children: [
        const ModalBarrier(dismissible: false, color: Color(0x99403831)),
        SafeArea(
            child: Center(
                child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: .92, end: 1),
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: 430,
                  height: _won ? 268 : 312,
                  child: Material(
                      color: Colors.transparent,
                      child: CustomPaint(
                        painter: const _ResultBoard(),
                        child: Stack(alignment: Alignment.topCenter, children: [
                          Positioned(
                              top: 21,
                              child: Text('MÀN ${widget.game.level.id}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF7A6C4D),
                                      fontWeight: FontWeight.w800))),
                          Positioned(
                              top: 37,
                              child: SizedBox(
                                  width: 92,
                                  height: 82,
                                  child: AnimatedBuilder(
                                      animation: _animation,
                                      builder: (context, _) => CustomPaint(
                                            painter: _ResultCat(
                                                _portrait,
                                                math.min(
                                                    _frameCount - 1,
                                                    (_animation.value *
                                                            _frameCount)
                                                        .floor())),
                                          )))),
                          Positioned(
                              top: 122,
                              left: 24,
                              right: 24,
                              child: Semantics(
                                  liveRegion: true,
                                  child: Text(
                                      _won ? 'VỀ NHÀ RỒI!' : 'HẾT GIỜ RỒI!',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 27,
                                          height: 1.15,
                                          fontWeight: FontWeight.w900,
                                          color: _won
                                              ? const Color(0xFF376B52)
                                              : const Color(0xFFAA6751))))),
                          if (!_won)
                            const Positioned(
                                top: 164,
                                left: 40,
                                right: 40,
                                child: Text(
                                    'Mấy bé còn mải chơi.\nMình thử thêm lần nữa nhé!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 14,
                                        height: 1.5,
                                        color: Color(0xFF70644A)))),
                          Positioned(
                              left: 38,
                              right: 38,
                              bottom: 28,
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _ResultButton(
                                        tooltip: 'Về chọn màn',
                                        icon: Icons.cottage_rounded,
                                        onPressed: widget.onHome),
                                    const SizedBox(width: 10),
                                    if (next) ...[
                                      _ResultButton(
                                          tooltip: 'Chơi lại',
                                          icon: Icons.replay_rounded,
                                          onPressed: widget.game.restartRound),
                                      const SizedBox(width: 10),
                                    ],
                                    Expanded(
                                        child: _ResultButton(
                                            tooltip:
                                                next ? 'Màn tiếp' : 'Chơi lại',
                                            icon: next
                                                ? Icons.arrow_forward_rounded
                                                : Icons.replay_rounded,
                                            label:
                                                next ? 'MÀN TIẾP' : 'CHƠI LẠI',
                                            primary: true,
                                            won: _won,
                                            onPressed: next
                                                ? widget.game.onNextLevel!
                                                : widget.game.restartRound)),
                                  ])),
                        ]),
                      )),
                )),
          ),
        ))),
      ]),
    );
  }
}

class _ResultButton extends StatelessWidget {
  const _ResultButton(
      {required this.tooltip,
      required this.icon,
      required this.onPressed,
      this.label,
      this.primary = false,
      this.won = false});
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final String? label;
  final bool primary, won;

  @override
  Widget build(BuildContext context) {
    final green = primary && won;
    final foreground =
        green ? const Color(0xFFFFF6DC) : const Color(0xFF70502F);
    return Tooltip(
        message: tooltip,
        child: Container(
          height: 48,
          width: label == null ? 48 : null,
          decoration:
              BoxDecoration(borderRadius: BorderRadius.circular(8), boxShadow: [
            BoxShadow(
                color:
                    green ? const Color(0xFF315740) : const Color(0xFFB49460),
                offset: const Offset(0, 4)),
          ]),
          child: Material(
            color: green
                ? const Color(0xFF568667)
                : primary
                    ? const Color(0xFFF6C967)
                    : const Color(0xFFE6D8B3),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                    color: green
                        ? const Color(0xFF315740)
                        : const Color(0xFFB49460),
                    width: 1.5)),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(8),
              child: Semantics(
                  button: true,
                  label: tooltip,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 23, color: foreground),
                        if (label != null) ...[
                          const SizedBox(width: 7),
                          Text(label!,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: foreground))
                        ],
                      ])),
            ),
          ),
        ));
  }
}

class _ResultCat extends CustomPainter {
  const _ResultCat(this.image, this.frame);
  final ui.Image image;
  final int frame;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawOval(
        Rect.fromLTWH(size.width * .18, size.height * .81, size.width * .64, 7),
        Paint()..color = const Color(0x22507843));
    final frameSize = image.height.toDouble();
    final side = math.min(size.width, size.height);
    canvas.drawImageRect(
        image,
        Rect.fromLTWH(frame * frameSize, 0, frameSize, frameSize),
        Rect.fromCenter(
            center: size.center(Offset.zero), width: side, height: side),
        Paint()..filterQuality = FilterQuality.medium);
  }

  @override
  bool shouldRepaint(covariant _ResultCat oldDelegate) =>
      image != oldDelegate.image || frame != oldDelegate.frame;
}

class _ResultBoard extends CustomPainter {
  const _ResultBoard();
  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(3), const Radius.circular(8));
    canvas.drawRRect(outer.shift(const Offset(0, 5)),
        Paint()..color = const Color(0x55412F1C));
    canvas.drawRRect(outer, Paint()..color = const Color(0xFFAB8453));
    canvas.drawRRect(
        outer.deflate(3), Paint()..color = const Color(0xFFD5B478));
    final inner = outer.deflate(11);
    canvas.drawRRect(inner, Paint()..color = const Color(0xFFFBF4DC));
    canvas.drawRRect(
        inner,
        Paint()
          ..color = const Color(0xFFA68050)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    for (final x in [9.0, size.width - 9]) {
      for (final y in [23.0, size.height - 23]) {
        canvas.drawCircle(
            Offset(x, y), 2, Paint()..color = const Color(0xFF7E6648));
      }
    }
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(side < 0 ? 38 : size.width - 38, 74);
      canvas.scale(side, 1);
      final stem = Paint()
        ..color = const Color(0xFF739465)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;
      canvas.drawPath(
          Path()
            ..moveTo(0, 33)
            ..quadraticBezierTo(14, 5, 0, -24),
          stem);
      for (var i = 0; i < 5; i++) {
        final y = 22 - i * 10.0;
        final lean = i.isEven ? -1.0 : 1.0;
        canvas.drawPath(
            Path()
              ..moveTo(5, y)
              ..quadraticBezierTo(5 + lean * 21, y - 17, 5 + lean * 18, y - 4)
              ..quadraticBezierTo(5 + lean * 12, y + 4, 5, y)
              ..close(),
            Paint()
              ..color =
                  i.isEven ? const Color(0xFF94AE79) : const Color(0xFF779B6C));
      }
      canvas.restore();
    }
    final grain = math.Random(45);
    for (var i = 0; i < 30; i++) {
      final x = 20 + grain.nextDouble() * (size.width - 40);
      canvas.drawLine(
          Offset(x, 7),
          Offset(math.min(size.width - 12, x + 10), 8),
          Paint()
            ..color = const Color(0x4489673D)
            ..strokeWidth = .8);
    }
  }

  @override
  bool shouldRepaint(covariant _ResultBoard oldDelegate) => false;
}
