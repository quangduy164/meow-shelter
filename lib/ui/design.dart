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
  static const surfaceRaised = Color(0xFFFFFBF0);
  static const surfaceMuted = Color(0xFFEDE6D2);
  static const surfaceGlass = Color(0xF2FFF4DA);
  static const borderSoft = Color(0x44B27A3E);
  static const borderMedium = Color(0x99B27A3E);
  static const success = Color(0xFF3C8065);
  static const danger = Color(0xFFAF6252);
  static const info = Color(0xFF3E9FB0);
  static const selectionBackdrop = Color(0xF0243E3A);
  static const selectionSurface = Color(0xFF36554C);
  static const selectionBorder = Color(0x447CA68D);
  static const selectedFill = Color(0xFFFFE9B9);
  static const shadowColor = Color(0x55000000);
  static const controlShadowColor = Color(0x40000000);
  static const modeFishing = Color(0xFF3E9FB0);
  static const modeReturnHome = Color(0xFF5E9A48);
  static const modeRescue = Color(0xFFE0703F);
  static const modeHerd = Color(0xFF8277B2);
  static const modeCamp = Color(0xFFC85A7C);

  static const double space2 = 2;
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 24;
  static const double space2xl = 32;
  static const double radiusXs = 6;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusControl = 14;
  static const double radiusLg = 16;
  static const double radiusCard = 20;
  static const double radiusXl = 24;
  static const double borderThin = 1;
  static const double borderSubtle = 1.5;
  static const double borderControl = 2;
  static const double borderRaised = 2.5;
  static const double borderStrong = 3;
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;
  static const double iconXl = 32;
  static const double touchTarget = 48;
  static const double controlHeight = 40;
  static const double compactHeight = 32;
  static const double buttonDepth = 4;
  static const double featureDepth = 6;
  static const double dialogWidth = 600;
  static const double wideDialogWidth = 860;
  static const double resultWidth = 500;
  static const double disabledOpacity = .45;
  static const pressDuration = Duration(milliseconds: 70);
  static const fastDuration = Duration(milliseconds: 120);
  static const transitionDuration = Duration(milliseconds: 220);
  static const overlayDuration = Duration(milliseconds: 260);
  static const cardShadow = [
    BoxShadow(color: shadowColor, blurRadius: 8, offset: Offset(0, 4)),
  ];
  static const controlShadow = [
    BoxShadow(color: controlShadowColor, blurRadius: 5, offset: Offset(0, 3)),
  ];

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
    color: surfaceGlass,
    borderRadius: BorderRadius.circular(radiusCard),
    border: Border.all(color: wood, width: borderStrong),
    boxShadow: cardShadow,
  );

  static final insetCard = BoxDecoration(
    color: surfaceRaised,
    borderRadius: BorderRadius.circular(radiusMd),
    border: Border.all(color: borderSoft, width: borderThin),
  );

  static final dialogShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusCard),
      side: const BorderSide(color: wood, width: borderStrong));

  /// Gold action button (playable rows, confirm, buy).
  static final primary = ElevatedButton.styleFrom(
    backgroundColor: gold,
    foregroundColor: ink,
    disabledBackgroundColor: mutedFill,
    disabledForegroundColor: mutedText,
    elevation: 2,
    textStyle: buttonText,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusControl),
        side: const BorderSide(color: goldEdge, width: borderControl)),
  );

  /// Cream secondary button with a wooden border.
  static final secondary = ElevatedButton.styleFrom(
    backgroundColor: cream,
    foregroundColor: ink,
    disabledBackgroundColor: mutedFill,
    disabledForegroundColor: mutedText,
    elevation: 2,
    textStyle: buttonText,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusControl),
        side: const BorderSide(color: wood, width: borderControl)),
  );

  static final outlined = OutlinedButton.styleFrom(
    foregroundColor: ink,
    disabledForegroundColor: mutedText,
    textStyle: buttonText,
    side: const BorderSide(color: wood, width: borderSubtle),
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusControl)),
  );

  /// Material controls and custom game controls share the same foundation.
  static final theme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    textTheme: textTheme,
    colorScheme: const ColorScheme.light(
      primary: goldEdge,
      onPrimary: cream,
      secondary: success,
      onSecondary: cream,
      surface: cream,
      onSurface: ink,
      error: danger,
      onError: cream,
    ),
    scaffoldBackgroundColor: cream,
    disabledColor: mutedText,
    dividerColor: borderSoft,
    elevatedButtonTheme: ElevatedButtonThemeData(style: primary),
    outlinedButtonTheme: OutlinedButtonThemeData(style: outlined),
    textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
      foregroundColor: goldEdge,
      disabledForegroundColor: mutedText,
      textStyle: buttonText,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusControl)),
    )),
    iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
      foregroundColor: ink,
      disabledForegroundColor: mutedText,
      minimumSize: const Size.square(touchTarget),
      iconSize: iconMd,
    )),
    dialogTheme: DialogTheme(
      backgroundColor: cream,
      surfaceTintColor: Colors.transparent,
      shape: dialogShape,
      titleTextStyle: title,
      contentTextStyle: bodyText,
      insetPadding: const EdgeInsets.all(spaceLg),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
          color: ink, borderRadius: BorderRadius.circular(radiusSm)),
      textStyle: captionText.copyWith(color: cream),
      padding:
          const EdgeInsets.symmetric(horizontal: spaceSm, vertical: spaceXs),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: cream,
      selectedColor: gold,
      disabledColor: mutedFill,
      labelStyle: bodyText,
      secondaryLabelStyle: bodyText,
      side: const BorderSide(color: wood, width: borderSubtle),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusControl)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? mutedText
              : states.contains(WidgetState.selected)
                  ? goldEdge
                  : surfaceRaised),
      trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? mutedFill
              : states.contains(WidgetState.selected)
                  ? gold
                  : mutedBorder),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: goldEdge,
      inactiveTrackColor: mutedFill,
      thumbColor: goldEdge,
      trackHeight: 5,
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
      overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
      valueIndicatorTextStyle: buttonText,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: goldEdge),
  );
}
