import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../design.dart';

/// Paw-shaped shutter between screens: a paw-shaped window over the old
/// screen shrinks to nothing, the screen is briefly covered, then the window
/// grows again over the new screen. Popping plays it backwards. Game screens
/// that are still loading continue with [GameLoading] in the same colour.
class PawPageTransitionsBuilder extends PageTransitionsBuilder {
  const PawPageTransitionsBuilder();

  @override
  Duration get transitionDuration => DS.pageTransitionDuration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      _PawShutter(animation: animation, child: child);
}

class _PawShutter extends StatelessWidget {
  const _PawShutter({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  // 0..closeEnd: window closes on the old screen; openStart..1: it opens on
  // the new one. The short gap between them is the fully covered moment.
  static const closeEnd = .46, openStart = .54;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (context, child) {
          final t = animation.value;
          // Settled routes pay nothing: no clip, no extra layer.
          if (t >= 1) return child!;
          final opening = t >= openStart;
          final window = opening
              ? Curves.easeOutCubic.transform((t - openStart) / (1 - openStart))
              : 1 - Curves.easeInCubic.transform(math.min(1, t / closeEnd));
          return Stack(fit: StackFit.expand, children: [
            // Stays built (games keep loading) but hidden until the reveal.
            Offstage(offstage: !opening, child: child),
            IgnorePointer(
              child: CustomPaint(painter: _ShutterPainter(window)),
            ),
          ]);
        },
      );
}

class _ShutterPainter extends CustomPainter {
  _ShutterPainter(this.window);

  /// 0 = fully covered, 1 = the paw window covers the whole screen.
  final double window;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    // At full size the main pad alone covers every corner.
    final paw = _pawPath(center, size.longestSide * 1.25 * window);
    // Even-odd fill punches the paw out of the screen rect; the pads never
    // overlap, so this matches a path difference without the boolean op.
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Offset.zero & size)
        ..addPath(paw, Offset.zero),
      Paint()..color = DS.pageTransitionColor,
    );
    if (window > 0 && window < 1) {
      canvas.drawPath(
        paw,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = DS.gold,
      );
    }
  }

  /// A paw [scale] units tall around [c]: one big pad and four toes.
  static Path _pawPath(Offset c, double scale) {
    final path = Path();
    if (scale <= 0) return path;
    Rect oval(double x, double y, double w, double h) => Rect.fromCenter(
        center: c + Offset(x, y) * scale, width: w * scale, height: h * scale);
    path.addOval(oval(0, .12, 1.0, .82));
    path.addOval(oval(-.52, -.42, .30, .38));
    path.addOval(oval(-.18, -.62, .30, .38));
    path.addOval(oval(.18, -.62, .30, .38));
    path.addOval(oval(.52, -.42, .30, .38));
    return path;
  }

  @override
  bool shouldRepaint(_ShutterPainter old) => old.window != window;
}
