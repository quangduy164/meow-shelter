import 'package:material_ui/material_ui.dart';

import '../design.dart';
import 'game_glyphs.dart';
import 'game_pressable.dart';

/// Gold 3D round button used for back / home / help / close in every mode.
/// Pass a hand-drawn [glyph] (preferred) or a Material [icon].
class RoundButton extends StatelessWidget {
  const RoundButton({
    super.key,
    this.icon,
    this.glyph,
    required this.onPressed,
    this.tooltip,
    this.size = DS.touchTarget,
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

/// Flat navigation control with a compact face and a full touch target.
class FlatRoundButton extends StatelessWidget {
  const FlatRoundButton({
    super.key,
    this.glyph,
    this.icon,
    required this.tooltip,
    required this.onPressed,
  }) : assert(glyph != null || icon != null);

  final GameGlyph? glyph;
  final IconData? icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
      message: tooltip,
      child: Material(
          type: MaterialType.transparency,
          child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: SizedBox.square(
                  dimension: 44,
                  child: Center(
                      child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                              color: DS.cream.withValues(alpha: .92),
                              shape: BoxShape.circle),
                          child: Center(
                              child: glyph != null
                                  ? GameGlyphView(glyph!, size: 20)
                                  : Icon(icon, size: 20, color: DS.ink))))))));
}
