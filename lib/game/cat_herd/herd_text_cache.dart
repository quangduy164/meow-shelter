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
  // Least recently used first: a hit moves to the back, and only the oldest
  // label is dropped when full. Clearing everything at once could dispose a
  // painter a caller is still holding for the same frame.
  final hit = _cache.remove(key);
  if (hit != null) return _cache[key] = hit;
  if (_cache.length >= 120) _cache.remove(_cache.keys.first)?.dispose();
  return _cache[key] = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: size,
              color: color,
              fontWeight: weight,
              height: height,
              shadows: shadows)),
      textDirection: TextDirection.ltr,
      textAlign: align)
    ..layout(maxWidth: maxWidth ?? double.infinity);
}
