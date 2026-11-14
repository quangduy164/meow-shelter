import 'dart:ui';

import 'package:flame/camera.dart';

/// World-space area the camera is drawing right now, padded so shadows and
/// glows that stick out of a component's box don't pop at the screen edge.
/// Null outside a camera render pass (then callers just draw).
Rect? visibleWorld({double pad = 80}) =>
    CameraComponent.currentCamera?.visibleWorldRect.inflate(pad);

/// Whether the horizontal span [left]..[right] is off screen.
bool offscreenX(double left, double right) {
  final view = visibleWorld();
  return view != null && (right < view.left || left > view.right);
}
