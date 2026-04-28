import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/generated/app_localizations.dart';
import 'ui/core/themes/themes.dart';
import 'ui/onboarding/widgets/onboarding_screen.dart';

void main() {
  runApp(const MambaGrowthApp());
}

class MambaGrowthApp extends StatelessWidget {
  const MambaGrowthApp({super.key});

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mamba Growth',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: supportedLocales,
      localeResolutionCallback: _resolveLocale,
      home: OnboardingScreen(
        onContinue: () => HapticFeedback.mediumImpact(),
      ),
    );
  }

  static Locale _resolveLocale(
    Locale? deviceLocale,
    Iterable<Locale> supported,
  ) {
    if (deviceLocale?.languageCode == 'pt') {
      return const Locale('pt');
    }
    return const Locale('en');
  }
}
