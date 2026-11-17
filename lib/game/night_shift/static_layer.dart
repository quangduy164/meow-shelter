import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';

/// Static scenery rasterised once into an image. Replaying a recorded
/// Picture still re-runs every path, gradient and layer each frame; an image
/// is one textured quad.
class StaticLayer {
  ui.Image? _image;
  Size _size = Size.zero;
  static final _paint = Paint()..filterQuality = FilterQuality.medium;

  void clear() {
    _image?.dispose();
    _image = null;
  }

  void draw(Canvas canvas, Size size, void Function(Canvas canvas) paint) {
    if (size.isEmpty) return;
    var image = _image;
    if (image == null || _size != size) {
      clear();
      final views = WidgetsBinding.instance.platformDispatcher.views;
      final ratio = math
          .min(2.0, views.isEmpty ? 1.0 : views.first.devicePixelRatio)
          .toDouble();
      final recorder = ui.PictureRecorder();
      final c = Canvas(recorder)..scale(ratio);
      paint(c);
      final picture = recorder.endRecording();
      image = _image = picture.toImageSync(
          (size.width * ratio).ceil(), (size.height * ratio).ceil());
      picture.dispose();
      _size = size;
    }
    canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Offset.zero & size,
        _paint);
  }
}
