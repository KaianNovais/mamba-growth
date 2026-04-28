import 'package:firebase_auth/firebase_auth.dart';

/// Categorias de erro de autenticação que a UI conhece.
///
/// Mantém o vocabulário do app independente de codes do Firebase.
enum AuthErrorKind {
  invalidCredentials,
  emailAlreadyInUse,
  weakPassword,
  userDisabled,
  networkError,
  tooManyRequests,
  googleSignInFailed,
  unknown,
}

/// Exceção de domínio devolvida via `Result.error(...)` pelo
/// AuthRepository. View consome [kind] para escolher a mensagem
/// localizada — não precisa conhecer o erro original.
class AuthException implements Exception {
  const AuthException(this.kind, [this.cause]);

  final AuthErrorKind kind;
  final Object? cause;

  factory AuthException.fromFirebase(FirebaseAuthException e) {
    final kind = switch (e.code) {
      'invalid-credential' ||
      'invalid-email' ||
      'wrong-password' ||
      'user-not-found' =>
        AuthErrorKind.invalidCredentials,
      'email-already-in-use' => AuthErrorKind.emailAlreadyInUse,
      'weak-password' => AuthErrorKind.weakPassword,
      'user-disabled' => AuthErrorKind.userDisabled,
      'network-request-failed' => AuthErrorKind.networkError,
      'too-many-requests' => AuthErrorKind.tooManyRequests,
      _ => AuthErrorKind.unknown,
    };
    return AuthException(kind, e);
  }

  factory AuthException.googleSignInFailed(Object cause) =>
      AuthException(AuthErrorKind.googleSignInFailed, cause);

  factory AuthException.unknown(Object cause) =>
      AuthException(AuthErrorKind.unknown, cause);

  @override
  String toString() => 'AuthException(kind: $kind, cause: $cause)';
}

/// Sinaliza que o usuário cancelou o flow do Google Sign-In.
/// A UI ignora silenciosamente (não mostra mensagem de erro).
class AuthCancelledException implements Exception {
  const AuthCancelledException();

  @override
  String toString() => 'AuthCancelledException';
}
