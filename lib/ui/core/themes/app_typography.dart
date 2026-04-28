import 'package:flutter/material.dart';

class AppFontFamily {
  AppFontFamily._();
  static const sans = 'Geist';
  static const mono = 'GeistMono';
}

@immutable
class AppTypography extends ThemeExtension<AppTypography> {
  const AppTypography({
    required this.numericDisplay,
    required this.numericLarge,
    required this.numericMedium,
    required this.numericSmall,
    required this.caption,
  });

  final TextStyle numericDisplay;
  final TextStyle numericLarge;
  final TextStyle numericMedium;
  final TextStyle numericSmall;
  final TextStyle caption;

  static const _mono = AppFontFamily.mono;
  static const _sans = AppFontFamily.sans;

  static const dark = AppTypography(
    numericDisplay: TextStyle(
      fontFamily: _mono,
      fontWeight: FontWeight.w600,
      fontSize: 56,
      height: 1.0,
      letterSpacing: -1.5,
    ),
    numericLarge: TextStyle(
      fontFamily: _mono,
      fontWeight: FontWeight.w600,
      fontSize: 32,
      height: 1.1,
      letterSpacing: -0.5,
    ),
    numericMedium: TextStyle(
      fontFamily: _mono,
      fontWeight: FontWeight.w500,
      fontSize: 18,
      height: 1.2,
    ),
    numericSmall: TextStyle(
      fontFamily: _mono,
      fontWeight: FontWeight.w400,
      fontSize: 13,
      height: 1.3,
    ),
    caption: TextStyle(
      fontFamily: _sans,
      fontWeight: FontWeight.w400,
      fontSize: 11,
      height: 1.3,
      letterSpacing: 0.4,
    ),
  );

  static TextTheme materialTextTheme(Color text) => TextTheme(
        displayLarge: TextStyle(
          fontFamily: _sans,
          fontWeight: FontWeight.w700,
          fontSize: 48,
          height: 1.1,
          letterSpacing: -1.2,
          color: text,
        ),
        displayMedium: TextStyle(
          fontFamily: _sans,
          fontWeight: FontWeight.w700,
          fontSize: 36,
          height: 1.15,
          letterSpacing: -0.8,
          color: text,
        ),
        displaySmall: TextStyle(
          fontFamily: _sans,
          fontWeight: FontWeight.w600,
          fontSize: 30,
          height: 1.2,
          letterSpacing: -0.4,
          color: text,
        ),
        headlineLarge: TextStyle(
          fontFamily: _sans,
          fontWeight: FontWeight.w600,
          fontSize: 24,
          height: 1.25,
          letterSpacing: -0.2,
          color: text,
        ),
        headlineMedium: TextStyle(
          fontFamily: _sans,
          fontWeight: FontWeight.w600,
          fontSize: 20,
          height: 1.3,
          color: text,
        ),
        headlineSmall: TextStyle(
          fontFamily: _sans,
          fontWeight: FontWeight.w600,
          fontSize: 18,
          height: 1.35,
          color: text,
        ),
        titleLarge: TextStyle(
          fontFamily: _sans,
          fontWeight: FontWeight.w600,
          fontSize: 17,
          height: 1.35,
          color: text,
        ),
        titleMedium: TextStyle(
          fontFamily: _sans,
          fontWeight: FontWeight.w600,
          fontSize: 15,
          height: 1.4,
          color: text,
        ),
        titleSmall: TextStyle(
          fontFamily: _sans,
          fontWeight: FontWeight.w600,
          fontSize: 13,
          height: 1.4,
          color: text,
        ),
        bodyLarge: TextStyle(
          fontFamily: _sans,
          fontWeight: FontWeight.w400,
          fontSize: 16,
          height: 1.5,
          color: text,
        ),
        bodyMedium: TextStyle(
          fontFamily: _sans,
          fontWeight: FontWeight.w400,
          fontSize: 14,
          height: 1.5,
          color: text,
        ),
        bodySmall: TextStyle(
          fontFamily: _sans,
          fontWeight: FontWeight.w400,
          fontSize: 12,
          height: 1.45,
          color: text,
        ),
        labelLarge: TextStyle(
          fontFamily: _sans,
          fontWeight: FontWeight.w600,
          fontSize: 14,
          height: 1.3,
          letterSpacing: 0.1,
          color: text,
        ),
        labelMedium: TextStyle(
          fontFamily: _sans,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          height: 1.3,
          letterSpacing: 0.2,
          color: text,
        ),
        labelSmall: TextStyle(
          fontFamily: _sans,
          fontWeight: FontWeight.w600,
          fontSize: 11,
          height: 1.3,
          letterSpacing: 0.3,
          color: text,
        ),
      );

  @override
  AppTypography copyWith({
    TextStyle? numericDisplay,
    TextStyle? numericLarge,
    TextStyle? numericMedium,
    TextStyle? numericSmall,
    TextStyle? caption,
  }) {
    return AppTypography(
      numericDisplay: numericDisplay ?? this.numericDisplay,
      numericLarge: numericLarge ?? this.numericLarge,
      numericMedium: numericMedium ?? this.numericMedium,
      numericSmall: numericSmall ?? this.numericSmall,
      caption: caption ?? this.caption,
    );
  }

  @override
  AppTypography lerp(ThemeExtension<AppTypography>? other, double t) {
    if (other is! AppTypography) return this;
    return AppTypography(
      numericDisplay: TextStyle.lerp(numericDisplay, other.numericDisplay, t)!,
      numericLarge: TextStyle.lerp(numericLarge, other.numericLarge, t)!,
      numericMedium: TextStyle.lerp(numericMedium, other.numericMedium, t)!,
      numericSmall: TextStyle.lerp(numericSmall, other.numericSmall, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
    );
  }
}
