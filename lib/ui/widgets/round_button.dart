import 'package:flutter/material.dart';

import '../design.dart';
import 'game_glyphs.dart';
import 'return_home_buttons.dart';

/// Gold 3D round button used for back / home / help / close in every mode.
/// Pass a hand-drawn [glyph] (preferred) or a Material [icon].
class RoundButton extends StatelessWidget {
  const RoundButton({
    super.key,
    this.icon,
    this.glyph,
    required this.onPressed,
    this.tooltip,
    this.size = 48,
  }) : assert(icon != null || glyph != null);
  final IconData? icon;
  final GameGlyph? glyph;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;

  String get _label =>
      tooltip ??
      switch (glyph) {
        GameGlyph.back => 'Quay lại',
        GameGlyph.close => 'Đóng',
        GameGlyph.home => 'Về Trang chủ',
        null => '',
      };

  // UnconstrainedBox keeps the fixed size even inside tight parents
  // (e.g. a Stack with StackFit.expand).
  @override
  Widget build(BuildContext context) => UnconstrainedBox(
        child: RoundGameButton(
          tooltip: _label,
          onPressed: onPressed,
          size: size,
          face: DS.gold,
          base: DS.goldEdge,
          child: glyph != null
              ? GameGlyphView(glyph!, size: size * .56)
              : Icon(icon, color: DS.ink, size: size * .5),
        ),
      );
}
