import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.border,
    required this.borderDim,
    required this.text,
    required this.textDim,
    required this.textDimmer,
    required this.accent,
    required this.accentDim,
  });

  final Color bg;
  final Color surface;
  final Color surface2;
  final Color border;
  final Color borderDim;
  final Color text;
  final Color textDim;
  final Color textDimmer;
  final Color accent;
  final Color accentDim;

  static const dark = AppColors(
    bg: Color(0xFF0A0A0B),
    surface: Color(0xFF15151A),
    surface2: Color(0xFF1F1F25),
    border: Color(0xFF2A2A30),
    borderDim: Color(0xFF1F1F25),
    text: Color(0xFFF5F5F7),
    textDim: Color(0xFF8A8A93),
    textDimmer: Color(0xFF55555E),
    accent: Color(0xFFD4A24C),
    accentDim: Color(0xFF8A6A30),
  );

  @override
  AppColors copyWith({
    Color? bg,
    Color? surface,
    Color? surface2,
    Color? border,
    Color? borderDim,
    Color? text,
    Color? textDim,
    Color? textDimmer,
    Color? accent,
    Color? accentDim,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      border: border ?? this.border,
      borderDim: borderDim ?? this.borderDim,
      text: text ?? this.text,
      textDim: textDim ?? this.textDim,
      textDimmer: textDimmer ?? this.textDimmer,
      accent: accent ?? this.accent,
      accentDim: accentDim ?? this.accentDim,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderDim: Color.lerp(borderDim, other.borderDim, t)!,
      text: Color.lerp(text, other.text, t)!,
      textDim: Color.lerp(textDim, other.textDim, t)!,
      textDimmer: Color.lerp(textDimmer, other.textDimmer, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentDim: Color.lerp(accentDim, other.accentDim, t)!,
    );
  }
}
