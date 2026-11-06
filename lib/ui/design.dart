import 'package:flutter/material.dart';

/// Shared design tokens; see DESIGN.md. Menus, dialogs and overlays should
/// take colours and shapes from here instead of hard-coding near-duplicates.
abstract final class DS {
  static const ink = Color(0xFF5A3214);
  static const cream = Color(0xFFFFF4DA);
  static const wood = Color(0xFFB27A3E);
  static const gold = Color(0xFFFFC24D);
  static const goldEdge = Color(0xFF9A6028);
  static const star = Color(0xFFFFC23D);
  static const label = Color(0xFFB0703A);
  static const soft = Color(0xFF8A6446);
  static const mutedFill = Color(0xFFD9CDB8);
  static const mutedBorder = Color(0xFFAA9C86);
  static const mutedText = Color(0xFF8E8270);

  /// Dim layer behind modal cards.
  static const scrim = Color(0x99302010);

  static const title = TextStyle(
      color: ink, fontSize: 21, fontWeight: FontWeight.w900, letterSpacing: 1);

  /// Cream card with a wooden border, as used by the chapter cards.
  static final card = BoxDecoration(
    color: const Color(0xF2FFF4DA),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: wood, width: 3),
    boxShadow: const [
      BoxShadow(color: Color(0x55000000), blurRadius: 8, offset: Offset(0, 4))
    ],
  );

  static final dialogShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: wood, width: 3));

  /// Gold action button (playable rows, confirm, buy).
  static final primary = ElevatedButton.styleFrom(
    backgroundColor: gold,
    foregroundColor: ink,
    disabledBackgroundColor: mutedFill,
    disabledForegroundColor: mutedText,
    elevation: 2,
    textStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: .5),
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: goldEdge, width: 2)),
  );

  /// Cream secondary button with a wooden border.
  static final secondary = ElevatedButton.styleFrom(
    backgroundColor: cream,
    foregroundColor: ink,
    elevation: 2,
    textStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: .5),
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: wood, width: 2)),
  );
}
