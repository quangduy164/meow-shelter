import 'package:flutter/material.dart';

import 'responsive.dart';

export 'responsive.dart';

/// Shared design tokens; see DESIGN.md. Menus, dialogs and overlays should
/// take colours and shapes from here instead of hard-coding near-duplicates.
///
/// All sizes are design units on a 375-tall reference screen; the app-wide
/// [UiScaleBox] in `responsive.dart` scales them to the real screen.
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

  // Typography uses design units; UiScaleBox handles screen/font scaling.
  static const double fontTitle = 16;
  static const double fontHeading = 14;
  static const double fontBody = 12;
  static const double fontButton = 12;
  static const double fontCaption = 10;
  static const double fontMicro = 9;
  static const double fontValue = 16;
  static const double fontDisplay = 18;

  // Artwork sizes are separate from readable interface text.
  static const double fontLogo = 60;
  static const double fontLogoCaption = 18;
  static const double fontSymbol = 28;

  static const title = TextStyle(
      color: ink,
      fontSize: fontTitle,
      fontWeight: FontWeight.w900,
      letterSpacing: .6);
  static const headingText =
      TextStyle(color: ink, fontSize: fontHeading, fontWeight: FontWeight.w900);
  static const bodyText =
      TextStyle(color: ink, fontSize: fontBody, fontWeight: FontWeight.w600);
  static const buttonText = TextStyle(
      fontFamily: 'Roboto',
      fontSize: fontButton,
      fontWeight: FontWeight.w900,
      letterSpacing: .3);
  static const captionText = TextStyle(
      color: soft, fontSize: fontCaption, fontWeight: FontWeight.w600);
  static const microText =
      TextStyle(color: soft, fontSize: fontMicro, fontWeight: FontWeight.w700);
  static const valueText =
      TextStyle(color: ink, fontSize: fontValue, fontWeight: FontWeight.w900);
  static const displayText =
      TextStyle(color: ink, fontSize: fontDisplay, fontWeight: FontWeight.w900);

  /// Also covers labels that do not specify a local TextStyle.
  static const textTheme = TextTheme(
    displayLarge: displayText,
    displayMedium: displayText,
    displaySmall: title,
    headlineLarge: displayText,
    headlineMedium: title,
    headlineSmall: title,
    titleLarge: title,
    titleMedium: headingText,
    titleSmall: bodyText,
    bodyLarge: bodyText,
    bodyMedium: bodyText,
    bodySmall: captionText,
    labelLarge: buttonText,
    labelMedium: captionText,
    labelSmall: microText,
  );

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
    textStyle: buttonText,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: goldEdge, width: 2)),
  );

  /// Cream secondary button with a wooden border.
  static final secondary = ElevatedButton.styleFrom(
    backgroundColor: cream,
    foregroundColor: ink,
    elevation: 2,
    textStyle: buttonText,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: wood, width: 2)),
  );
}
