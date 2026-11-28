import 'package:flutter/painting.dart';

/// Laid-out labels reused across frames. Game HUD text changes rarely, but
/// building and laying out a TextPainter every frame is one of the most
/// expensive parts of a Canvas frame.
class TextCache {
  static const _limit = 300;
  static final _cache =
      <(String, TextStyle, double, int, TextAlign), TextPainter>{};

  /// The returned painter is owned by the cache; callers must not dispose it.
  static TextPainter layout(String text, TextStyle style,
      {double maxWidth = double.infinity,
      int maxLines = 1,
      TextAlign textAlign = TextAlign.start}) {
    // Canvas text does not inherit the app theme font.
    if (style.fontFamily == null) style = style.copyWith(fontFamily: 'Nunito');
    final key = (text, style, maxWidth, maxLines, textAlign);
    final hit = _cache.remove(key);
    if (hit != null) return _cache[key] = hit;
    if (_cache.length >= _limit) _cache.remove(_cache.keys.first)?.dispose();
    return _cache[key] = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        textAlign: textAlign,
        maxLines: maxLines,
        ellipsis: '…')
      ..layout(maxWidth: maxWidth);
  }
}
