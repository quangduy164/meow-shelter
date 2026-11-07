import 'package:flutter/widgets.dart';

/// Responsive design units. See DESIGN.md › "Responsive layout".
///
/// The whole app is designed on a landscape screen [designHeight] tall.
/// [UiScaleBox] (installed once in `main.dart`) scales every route, dialog
/// and game canvas so that one design pixel becomes [UiScale.of] real
/// pixels. Inside the app, keep writing plain numbers (`width: 48`,
/// `fontSize: 14`): they are design units, not physical pixels.
abstract final class UiScale {
  /// Height of the reference screen (a typical phone held sideways).
  static const designHeight = 375.0;

  /// Small phones shrink at most this much; tablets grow at most this much.
  static const minScale = .8;
  static const maxScale = 2.0;

  /// Largest system font scale honoured, so big accessibility fonts stay
  /// readable without breaking fixed game layouts.
  static const maxTextScale = 1.15;

  /// Scale for a screen of [size] real logical pixels.
  static double forSize(Size size) =>
      (size.shortestSide / designHeight).clamp(minScale, maxScale);

  /// Scale currently applied to the app (1 inside tests without the box).
  static double of(BuildContext context) => _UiScaleScope.maybeOf(context) ?? 1;
}

/// Scales [child] uniformly so its layout happens in design units: the
/// child sees a screen whose shorter side is about [UiScale.designHeight],
/// and the result is stretched back to the real screen.
class UiScaleBox extends StatelessWidget {
  const UiScaleBox({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final scale = UiScale.forSize(media.size);
    final virtual = media.size / scale;
    EdgeInsets down(EdgeInsets e) => e / scale;
    return _UiScaleScope(
      scale: scale,
      child: FittedBox(
        fit: BoxFit.fill,
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: virtual.width,
          height: virtual.height,
          child: MediaQuery(
            data: media.copyWith(
              size: virtual,
              padding: down(media.padding),
              viewPadding: down(media.viewPadding),
              viewInsets: down(media.viewInsets),
              systemGestureInsets: down(media.systemGestureInsets),
              // Keeps images and text rasterised at the real resolution.
              devicePixelRatio: media.devicePixelRatio * scale,
              textScaler:
                  media.textScaler.clamp(maxScaleFactor: UiScale.maxTextScale),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _UiScaleScope extends InheritedWidget {
  const _UiScaleScope({required this.scale, required super.child});
  final double scale;

  static double? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_UiScaleScope>()?.scale;

  @override
  bool updateShouldNotify(_UiScaleScope old) => scale != old.scale;
}
