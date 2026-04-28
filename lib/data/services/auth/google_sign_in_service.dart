import 'package:google_sign_in/google_sign_in.dart';

/// Wrap sobre o singleton [GoogleSignIn.instance] (versão 7.x).
///
/// Inicialização é lazy via [_ensureInitialized]. O método
/// [authenticateAndGetIdToken] retorna o `idToken` para o
/// repository montar a credencial do Firebase.
class GoogleSignInService {
  GoogleSignInService({GoogleSignIn? googleSignIn, this.serverClientId})
      : _signIn = googleSignIn ?? GoogleSignIn.instance;

  final GoogleSignIn _signIn;
  final String? serverClientId;

  Future<void>? _initialization;

  Future<void> _ensureInitialized() {
    return _initialization ??= _signIn.initialize(
      serverClientId: serverClientId,
    );
  }

  bool get supportsAuthenticate => _signIn.supportsAuthenticate();

  /// Autentica e devolve o `idToken` que o Firebase precisa.
  /// Lança [GoogleSignInException] (incluindo cancelamento) ou
  /// [_MissingIdTokenException] se o provedor não devolver token.
  Future<String> authenticateAndGetIdToken() async {
    await _ensureInitialized();
    final account = await _signIn.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const _MissingIdTokenException();
    }
    return idToken;
  }

  Future<void> signOut() async {
    await _ensureInitialized();
    await _signIn.signOut();
  }
}

class _MissingIdTokenException implements Exception {
  const _MissingIdTokenException();
  @override
  String toString() => 'Google Sign-In returned no idToken';
}
