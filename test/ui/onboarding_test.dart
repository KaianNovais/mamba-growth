import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mamba_growth/data/repositories/auth/auth_repository.dart';
import 'package:mamba_growth/data/repositories/fasting/fasting_repository.dart';
import 'package:mamba_growth/data/services/database/local_database.dart';
import 'package:mamba_growth/data/services/notifications/notification_service.dart';
import 'package:mamba_growth/domain/models/auth_user.dart';
import 'package:mamba_growth/domain/models/fast.dart';
import 'package:mamba_growth/domain/models/fasting_protocol.dart';
import 'package:mamba_growth/l10n/generated/app_localizations.dart';
import 'package:mamba_growth/main.dart';
import 'package:mamba_growth/ui/core/themes/themes.dart';
import 'package:mamba_growth/ui/onboarding/widgets/fasting_clock.dart';
import 'package:mamba_growth/ui/onboarding/widgets/onboarding_screen.dart';
import 'package:mamba_growth/utils/result.dart';

class _StubAuthRepository extends ChangeNotifier implements AuthRepository {
  @override
  AuthUser? get currentUser => null;

  @override
  bool get isAuthenticated => false;

  @override
  bool get isInitialized => true;

  @override
  Future<Result<void>> signInWithEmail({
    required String email,
    required String password,
  }) async =>
      const Result.ok(null);

  @override
  Future<Result<void>> signUpWithEmail({
    required String email,
    required String password,
  }) async =>
      const Result.ok(null);

  @override
  Future<Result<void>> signInWithGoogle() async => const Result.ok(null);

  @override
  Future<Result<void>> signOut() async => const Result.ok(null);
}

class _StubFastingRepository extends ChangeNotifier
    implements FastingRepository {
  @override
  Fast? get activeFast => null;

  @override
  FastingProtocol get selectedProtocol => FastingProtocol.defaultProtocol;

  @override
  bool get isInitialized => true;

  @override
  Future<Result<Fast>> startFast() async =>
      const Result.error(FastingException('stub'));

  @override
  Future<Result<Fast>> endFast() async =>
      const Result.error(FastingException('stub'));

  @override
  Future<void> setProtocol(FastingProtocol protocol) async {}

  @override
  Stream<List<Fast>> watchCompletedFasts() => const Stream.empty();
}

class _StubLocalDatabase extends LocalDatabase {
  @override
  Future<void> close() async {}
}

class _StubNotificationService extends NotificationService {
  @override
  Future<void> init() async {}

  @override
  Future<void> scheduleFastEnd({
    required DateTime endAt,
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> cancelFastEnd() async {}
}

MambaGrowthApp _buildApp({AuthRepository? auth}) => MambaGrowthApp(
      authRepository: auth ?? _StubAuthRepository(),
      fastingRepository: _StubFastingRepository(),
      notificationService: _StubNotificationService(),
      localDatabase: _StubLocalDatabase(),
    );

Widget _harness({Locale? locale, VoidCallback? onContinue}) {
  return MaterialApp(
    locale: locale,
    theme: AppTheme.dark(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: OnboardingScreen(onContinue: onContinue),
  );
}

List<TextSpan> _flattenSpans(InlineSpan root) {
  final out = <TextSpan>[];
  void walk(InlineSpan span) {
    if (span is TextSpan) {
      out.add(span);
      span.children?.forEach(walk);
    }
  }
  walk(root);
  return out;
}

RichText _richTextContaining(WidgetTester tester, String label) {
  for (final widget in tester.widgetList<RichText>(find.byType(RichText))) {
    final spans = _flattenSpans(widget.text);
    if (spans.any((span) => span.text == label)) return widget;
  }
  fail('No RichText found containing a span with text "$label"');
}

void main() {
  group('MambaGrowthApp locale resolution', () {
    testWidgets('renders English copy by default', (tester) async {
      await tester
          .pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Eat with purpose.\nFast with clarity.'), findsOneWidget);
      expect(find.text('FASTING & CALORIES'), findsOneWidget);
      expect(find.text('Get started'), findsOneWidget);
      expect(find.text('FASTING'), findsOneWidget);
    });

    testWidgets('renders Portuguese when device locale is pt', (tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale('pt', 'BR')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      await tester
          .pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Coma com propósito.\nJejue com clareza.'), findsOneWidget);
      expect(find.text('JEJUM & CALORIAS'), findsOneWidget);
      expect(find.text('Começar'), findsOneWidget);
      expect(find.text('EM JEJUM'), findsOneWidget);
    });

    testWidgets('falls back to English when device locale is unsupported',
        (tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale('fr')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      await tester
          .pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('FASTING & CALORIES'), findsOneWidget);
      expect(find.text('Get started'), findsOneWidget);
    });
  });

  group('OnboardingScreen — English copy', () {
    testWidgets('renders brand mark, eyebrow, title, subtitle and pillars',
        (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      expect(find.text('MAMBA GROWTH'), findsOneWidget);
      expect(find.text('FASTING & CALORIES'), findsOneWidget);
      expect(find.text('Eat with purpose.\nFast with clarity.'), findsOneWidget);
      expect(
        find.text(
          'Track every fast and every calorie in one place. '
          'No noise, no shame — just honest numbers showing your real progress.',
        ),
        findsOneWidget,
      );
      expect(find.text('AWARENESS'), findsOneWidget);
      expect(find.text('CONSISTENCY'), findsOneWidget);
      expect(find.text('VISION'), findsOneWidget);
    });

    testWidgets('renders the FastingClock with caption, time and footnote',
        (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      expect(find.byType(FastingClock), findsOneWidget);
      expect(find.text('FASTING'), findsOneWidget);
      expect(find.text('10:24'), findsOneWidget);
      expect(find.text('Sample day · 10h 24m of 16h'), findsOneWidget);
    });

    testWidgets('renders primary CTA labelled "Get started"', (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      expect(find.text('Get started'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('does not render the legacy secondary CTA', (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      expect(find.text('I already have an account'), findsNothing);
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets(
      'footer renders Terms and Privacy Policy with underline + medium weight',
      (tester) async {
        await tester.pumpWidget(_harness());
        await tester.pumpAndSettle();

        final footer = _richTextContaining(tester, 'Terms');
        final spans = _flattenSpans(footer.text);

        final terms = spans.firstWhere((span) => span.text == 'Terms');
        expect(terms.style?.decoration, TextDecoration.underline);
        expect(terms.style?.fontWeight, FontWeight.w500);

        final privacy =
            spans.firstWhere((span) => span.text == 'Privacy Policy');
        expect(privacy.style?.decoration, TextDecoration.underline);
        expect(privacy.style?.fontWeight, FontWeight.w500);
      },
    );
  });

  group('OnboardingScreen — Portuguese copy', () {
    testWidgets('renders all hero copy in PT', (tester) async {
      await tester.pumpWidget(_harness(locale: const Locale('pt')));
      await tester.pumpAndSettle();

      expect(find.text('JEJUM & CALORIAS'), findsOneWidget);
      expect(
          find.text('Coma com propósito.\nJejue com clareza.'), findsOneWidget);
      expect(find.text('EM JEJUM'), findsOneWidget);
      expect(find.text('Dia exemplo · 10h 24m de 16h'), findsOneWidget);
      expect(find.text('CONSCIÊNCIA'), findsOneWidget);
      expect(find.text('CONSISTÊNCIA'), findsOneWidget);
      expect(find.text('VISÃO'), findsOneWidget);
      expect(find.text('Começar'), findsOneWidget);
    });

    testWidgets(
      'PT footer emphasizes Termos and Política de Privacidade',
      (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('pt')));
        await tester.pumpAndSettle();

        final footer = _richTextContaining(tester, 'Termos');
        final spans = _flattenSpans(footer.text);

        final termos = spans.firstWhere((span) => span.text == 'Termos');
        expect(termos.style?.decoration, TextDecoration.underline);
        expect(termos.style?.fontWeight, FontWeight.w500);

        final politica = spans
            .firstWhere((span) => span.text == 'Política de Privacidade');
        expect(politica.style?.decoration, TextDecoration.underline);
        expect(politica.style?.fontWeight, FontWeight.w500);
      },
    );
  });

  group('OnboardingScreen — interactions', () {
    testWidgets('tapping primary CTA invokes onContinue', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_harness(onContinue: () => taps++));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byType(FilledButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      expect(taps, 1);
    });

    testWidgets('primary CTA is disabled when onContinue is null',
        (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.enabled, isFalse);
    });
  });
}
