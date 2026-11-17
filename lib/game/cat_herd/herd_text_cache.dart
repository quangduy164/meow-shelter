import 'package:flutter/painting.dart';

/// Laid-out labels reused across frames. Text layout is the most expensive
/// thing the herd painters did per frame; labels here are few and fixed.
final _cache = <String, TextPainter>{};

TextPainter herdLabel(String text, double size, Color color,
    {FontWeight weight = FontWeight.w900,
    double? maxWidth,
    TextAlign align = TextAlign.start,
    double? height,
    List<Shadow>? shadows}) {
  final key = '$text|$size|${color.toARGB32()}|${weight.value}|$maxWidth|'
      '${align.index}|$height|${shadows?.length}';
  final hit = _cache[key];
  if (hit != null) return hit;
  if (_cache.length > 120) {
    for (final painter in _cache.values) {
      painter.dispose();
    }
    _cache.clear();
  }
  return _cache[key] = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              fontSize: size,
              color: color,
              fontWeight: weight,
              height: height,
              shadows: shadows)),
      textDirection: TextDirection.ltr,
      textAlign: align)
    ..layout(maxWidth: maxWidth ?? double.infinity);
}
