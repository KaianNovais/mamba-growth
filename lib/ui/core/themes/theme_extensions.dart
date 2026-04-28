import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

extension AppThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get scheme => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  AppTypography get typo => Theme.of(this).extension<AppTypography>()!;
}
