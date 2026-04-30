import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';

/// Roda uma ação no `FirebaseAnalytics.instance` e engole qualquer erro.
///
/// Analytics nunca deve quebrar fluxo do usuário nem testes. Se o Firebase
/// não foi inicializado (ex.: testes de unidade), o acesso a `.instance`
/// lança sincronamente — daí o `try/catch`. Se a chamada futura falhar, o
/// `catchError` engole.
void safeAnalytics(Future<void> Function(FirebaseAnalytics) action) {
  try {
    unawaited(action(FirebaseAnalytics.instance).catchError((_) {}));
  } catch (_) {
    // Firebase não inicializado — no-op.
  }
}
