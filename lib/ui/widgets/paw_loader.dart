import 'dart:math';

import 'package:flutter/material.dart';

import '../design.dart';

/// Loading indicator: a little trail of cat paw prints that appear one after
/// another, as if a cat were walking across the box, then fade and repeat.
/// Use it everywhere instead of a spinning circle.
class PawLoader extends StatefulWidget {
  const PawLoader({super.key, this.size = DS.iconXl, this.color = DS.ink});

  /// Width and height of the square the trail walks across.
  final double size;
  final Color color;

  @override
  State<PawLoader> createState() => _PawLoaderState();
}

class _PawLoaderState extends State<PawLoader>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = .7; // every print shown, standing still
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Đang tải',
        child: RepaintBoundary(
          child: SizedBox.square(
            dimension: widget.size,
            child: CustomPaint(
                painter: _PawTrailPainter(_controller, widget.color)),
          ),
        ),
      );
}

class _PawTrailPainter extends CustomPainter {
  _PawTrailPainter(this.progress, this.color) : super(repaint: progress);
  final Animation<double> progress;
  final Color color;

  /// Prints along a diagonal, alternating left/right paws.
  static const _steps = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    final s = size.shortestSide;
    final paw = s / 5;
    // Walk from bottom-left to top-right.
    const angle = -pi / 4;
    final start = Offset(s * .27, s * .73);
    final end = Offset(s * .73, s * .27);
    for (var i = 0; i < _steps; i++) {
      // Each print lands in turn over the first 60%, all fade in the last 30%.
      final appear = ((t - i * .15) / .08).clamp(0.0, 1.0);
      final fade = ((1 - t) / .3).clamp(0.0, 1.0);
      final opacity = appear * fade;
      if (opacity <= 0) continue;
      final along = Offset.lerp(start, end, i / (_steps - 1))!;
      final side = i.isEven ? -1.0 : 1.0;
      final at = along +
          Offset(cos(angle + pi / 2), sin(angle + pi / 2)) * side * paw * .45;
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.rotate(angle + pi / 2);
      // A small "press" as the paw lands.
      canvas.scale(.8 + .2 * appear);
      _paw(canvas, paw, color.withOpacity(color.opacity * opacity));
      canvas.restore();
    }
  }

  /// One print centred on the origin, toes pointing up (-y).
  void _paw(Canvas canvas, double r, Color color) {
    final paint = Paint()..color = color;
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(0, r * .22), width: r * .9, height: r * .72),
        paint);
    for (final toe in const [
      Offset(-.42, -.18),
      Offset(-.15, -.42),
      Offset(.15, -.42),
      Offset(.42, -.18),
    ]) {
      canvas.drawOval(
          Rect.fromCenter(center: toe * r, width: r * .3, height: r * .36),
          paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PawTrailPainter old) => old.color != color;
}
