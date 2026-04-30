import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'data/repositories/auth/auth_repository.dart';
import 'data/repositories/auth/auth_repository_firebase.dart';
import 'data/repositories/fasting/fasting_repository.dart';
import 'data/repositories/fasting/fasting_repository_local.dart';
import 'data/repositories/meals/meals_repository.dart';
import 'data/repositories/meals/meals_repository_local.dart';
import 'data/services/auth/firebase_auth_service.dart';
import 'data/services/auth/google_sign_in_service.dart';
import 'data/services/database/local_database.dart';
import 'data/services/notifications/notification_service.dart';
import 'firebase_options.dart';
import 'l10n/generated/app_localizations.dart';
import 'routing/router.dart';
import 'ui/core/themes/themes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  final firebaseAuthService = FirebaseAuthService();
  final googleSignInService = GoogleSignInService();
  final authRepository = AuthRepositoryFirebase(
    firebaseAuthService: firebaseAuthService,
    googleSignInService: googleSignInService,
  );

  final localDatabase = LocalDatabase();
  final notificationService = NotificationService();
  await notificationService.init();

  // A copy é resolvida pela locale do device no momento do startFast.
  // Se o usuário trocar locale entre startFast e a notificação disparar,
  // ela ficará na locale do momento do agendamento — comportamento aceitável.
  final fastingRepository = FastingRepositoryLocal(
    database: localDatabase,
    notifications: notificationService,
    notificationCopyProvider: () {
      final locale = WidgetsBinding.instance.platformDispatcher.locale;
      final isPt = locale.languageCode == 'pt';
      return (
        title: isPt ? 'Jejum concluído' : 'Fast complete',
        body: isPt
            ? 'Você atingiu sua meta. Quebre o jejum quando estiver pronto.'
            : "You hit your goal. Break your fast when you're ready.",
      );
    },
  );

  final mealsRepository = MealsRepositoryLocal(database: localDatabase);

  runApp(MambaGrowthApp(
    authRepository: authRepository,
    fastingRepository: fastingRepository,
    mealsRepository: mealsRepository,
    notificationService: notificationService,
    localDatabase: localDatabase,
    routerObservers: [
      FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
    ],
  ));
}

class MambaGrowthApp extends StatelessWidget {
  const MambaGrowthApp({
    super.key,
    required this.authRepository,
    required this.fastingRepository,
    required this.mealsRepository,
    required this.notificationService,
    required this.localDatabase,
    this.routerObservers = const [],
  });

  final AuthRepository authRepository;
  final FastingRepository fastingRepository;
  final MealsRepository mealsRepository;
  final NotificationService notificationService;
  final LocalDatabase localDatabase;
  final List<NavigatorObserver> routerObservers;

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthRepository>.value(value: authRepository),
        ChangeNotifierProvider<FastingRepository>.value(value: fastingRepository),
        ChangeNotifierProvider<MealsRepository>.value(value: mealsRepository),
        Provider<NotificationService>.value(value: notificationService),
        Provider<LocalDatabase>.value(value: localDatabase),
      ],
      child: MaterialApp.router(
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
        routerConfig: buildRouter(
          authRepository: authRepository,
          observers: routerObservers,
        ),
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
