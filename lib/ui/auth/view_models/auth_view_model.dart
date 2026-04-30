import 'package:flutter/foundation.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../utils/analytics.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

enum AuthMode { signIn, signUp }

@immutable
class EmailPasswordInput {
  const EmailPasswordInput({required this.email, required this.password});
  final String email;
  final String password;
}

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({required AuthRepository authRepository})
      : _authRepository = authRepository {
    signInWithEmail = Command1<void, EmailPasswordInput>(_signInWithEmail);
    signUpWithEmail = Command1<void, EmailPasswordInput>(_signUpWithEmail);
    signInWithGoogle = Command0<void>(_signInWithGoogle);
  }

  final AuthRepository _authRepository;

  AuthMode _mode = AuthMode.signIn;
  AuthMode get mode => _mode;

  late final Command1<void, EmailPasswordInput> signInWithEmail;
  late final Command1<void, EmailPasswordInput> signUpWithEmail;
  late final Command0<void> signInWithGoogle;

  void toggleMode() {
    _mode = _mode == AuthMode.signIn ? AuthMode.signUp : AuthMode.signIn;
    signInWithEmail.clearResult();
    signUpWithEmail.clearResult();
    notifyListeners();
  }

  Future<Result<void>> _signInWithEmail(EmailPasswordInput input) async {
    final result = await _authRepository.signInWithEmail(
      email: input.email,
      password: input.password,
    );
    if (result is Ok<void>) {
      safeAnalytics((a) => a.logLogin(loginMethod: 'email'));
    }
    return result;
  }

  Future<Result<void>> _signUpWithEmail(EmailPasswordInput input) async {
    final result = await _authRepository.signUpWithEmail(
      email: input.email,
      password: input.password,
    );
    if (result is Ok<void>) {
      safeAnalytics((a) => a.logSignUp(signUpMethod: 'email'));
    }
    return result;
  }

  Future<Result<void>> _signInWithGoogle() async {
    final result = await _authRepository.signInWithGoogle();
    if (result is Ok<void>) {
      safeAnalytics((a) => a.logLogin(loginMethod: 'google'));
    }
    return result;
  }

  @override
  void dispose() {
    signInWithEmail.dispose();
    signUpWithEmail.dispose();
    signInWithGoogle.dispose();
    super.dispose();
  }
}
