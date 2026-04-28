import 'package:flutter/foundation.dart';

import '../../../domain/models/auth_user.dart';
import '../../../utils/result.dart';

/// SSOT do estado de autenticação.
///
/// Implementações estendem [ChangeNotifier] e disparam `notifyListeners`
/// quando [currentUser] muda — o GoRouter usa isso via `refreshListenable`
/// para reavaliar redirects.
///
/// [isInitialized] é falso até o primeiro evento do stream do
/// FirebaseAuth ser recebido. Sem isso, o splash não saberia se está
/// esperando ou se de fato o usuário não está logado.
abstract class AuthRepository extends ChangeNotifier {
  AuthUser? get currentUser;
  bool get isAuthenticated => currentUser != null;
  bool get isInitialized;

  Future<Result<void>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<Result<void>> signUpWithEmail({
    required String email,
    required String password,
  });

  Future<Result<void>> signInWithGoogle();

  Future<Result<void>> signOut();
}
