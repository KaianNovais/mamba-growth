# Firebase Auth Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Adicionar autenticação Firebase (email/senha + Google) com bottom sheet aberto pelo CTA "Start" do onboarding, sessão persistida e roteamento via `go_router` baseado no estado de auth.

**Architecture:** MVVM + Repository + Service do skill `flutter-expert` (case study Compass do time Flutter), com `ChangeNotifier` + `provider`. `AuthRepository` é a SSOT do `currentUser` e dispara o redirect do `GoRouter` via `refreshListenable`. `Result<T>` na borda repo→viewmodel; UI consome `Command0/Command1`. Design system de `lib/ui/core/themes` é única fonte de verdade.

**Tech Stack:** Flutter 3.11+, Dart 3, `firebase_auth ^6.4.0`, `google_sign_in ^7.2.0`, `go_router ^16.3.0`, `provider ^6.1.5`.

**Spec:** `docs/superpowers/specs/2026-04-28-firebase-auth-design.md`

> **Nota:** A spec original previa testes (utils, domain, data, viewmodel, widget, router). O usuário pediu para **não implementar testes** neste MVP. Todas as tarefas abaixo focam em código de produção. Testes ficam como dívida técnica documentada.

---

## File Structure

### Created files

| Path | Responsabilidade |
|---|---|
| `lib/utils/result.dart` | Sealed `Result<T>` com `Ok` / `Error`. |
| `lib/utils/command.dart` | `Command0`/`Command1` (re-entrancy guard, running/result). |
| `lib/domain/models/auth_user.dart` | Domain user imutável. |
| `lib/domain/models/auth_exception.dart` | `AuthException` (kind enum) + `AuthCancelledException`. |
| `lib/data/services/auth/firebase_auth_service.dart` | Wrap fino sobre `FirebaseAuth.instance`. |
| `lib/data/services/auth/google_sign_in_service.dart` | Wrap sobre `GoogleSignIn.instance` (7.x), devolve `idToken`. |
| `lib/data/repositories/auth/auth_repository.dart` | Abstract `ChangeNotifier` (SSOT do user). |
| `lib/data/repositories/auth/auth_repository_firebase.dart` | Implementação real combinando os dois services. |
| `lib/ui/auth/view_models/auth_view_model.dart` | ViewModel do sheet com `AuthMode` + 3 commands. |
| `lib/ui/auth/widgets/auth_bottom_sheet.dart` | Bottom sheet com show() estático + UI completa. |
| `lib/ui/core/widgets/brand_mark.dart` | `BrandMark` extraído de `onboarding_screen.dart` (reusado em splash). |
| `lib/ui/splash/widgets/splash_screen.dart` | Splash mínima durante boot. |
| `lib/ui/home/widgets/home_placeholder_screen.dart` | Placeholder pós-login com sign out. |
| `lib/routing/routes.dart` | Constantes de path/name. |
| `lib/routing/router.dart` | `buildRouter(authRepository:)` com redirect. |

### Modified files

| Path | Mudança |
|---|---|
| `pubspec.yaml` | Adicionar 3 deps. |
| `lib/main.dart` | Bootstrap async com `Firebase.initializeApp`, DI raiz, `MaterialApp.router`. |
| `lib/ui/onboarding/widgets/onboarding_screen.dart` | Remover `_BrandMark` privado (movido para core/widgets). |
| `lib/l10n/app_en.arb` | +27 strings. |
| `lib/l10n/app_pt.arb` | +27 strings. |
| `android/build.gradle` (se necessário) | Plugin `com.google.gms.google-services` no classpath. |
| `android/app/build.gradle` (se necessário) | Aplicar plugin `com.google.gms.google-services`. |

### Deleted files

| Path | Motivo |
|---|---|
| `test/widget_test.dart` | Template inicial referencia `MyApp` que não existe mais; sem testes no MVP. |

---

## Conventions

- **Static analysis:** `flutter analyze` (zero issues exigidos a cada task).
- **Codegen l10n:** `flutter gen-l10n` (executa baseado em `l10n.yaml`).
- **Commits:** Conventional Commits (`feat:`, `refactor:`, `chore:`, `docs:`). Cada task termina em commit.
- **Imports:** sempre relativos dentro de `lib/`.

---

## Task 1: Adicionar dependências

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Adicionar deps em `pubspec.yaml`**

Editar a seção `dependencies` para incluir:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: any
  cupertino_icons: ^1.0.8
  firebase_core: ^4.7.0
  firebase_auth: ^6.4.0
  google_sign_in: ^7.2.0
  go_router: ^16.3.0
  provider: ^6.1.5
```

(`dev_dependencies` permanece intacta — não adicionar `mocktail`.)

- [ ] **Step 2: Resolver pacotes**

Run: `cd C:/mamba_growth && flutter pub get`
Expected: "Got dependencies!" sem conflito de versões.

- [ ] **Step 3: Validar analyze**

Run: `cd C:/mamba_growth && flutter analyze`
Expected: "No issues found!"

- [ ] **Step 4: Commit**

```bash
git -C C:/mamba_growth add pubspec.yaml pubspec.lock
git -C C:/mamba_growth commit -m "chore(deps): add google_sign_in, go_router, provider"
```

---

## Task 2: `Result<T>` sealed class

**Files:**
- Create: `lib/utils/result.dart`

- [ ] **Step 1: Implementar `lib/utils/result.dart`**

```dart
/// Tipo de retorno padrão da borda Repository → ViewModel.
///
/// Em vez de exceções vazadas, repositories devolvem [Ok] em sucesso
/// ou [Error] em falha. ViewModels fazem `switch` no resultado.
sealed class Result<T> {
  const Result();
  const factory Result.ok(T value) = Ok<T>;
  const factory Result.error(Exception error) = Error<T>;
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Error<T> extends Result<T> {
  const Error(this.error);
  final Exception error;
}
```

- [ ] **Step 2: Validar analyze**

Run: `cd C:/mamba_growth && flutter analyze lib/utils/result.dart`
Expected: "No issues found!"

- [ ] **Step 3: Commit**

```bash
git -C C:/mamba_growth add lib/utils/result.dart
git -C C:/mamba_growth commit -m "feat(utils): add sealed Result<T> with Ok/Error"
```

---

## Task 3: `Command0` / `Command1`

**Files:**
- Create: `lib/utils/command.dart`

- [ ] **Step 1: Implementar `lib/utils/command.dart`**

```dart
import 'package:flutter/foundation.dart';

import 'result.dart';

/// Encapsula uma ação assíncrona com estado de execução.
///
/// `running` é true durante a execução. `result` carrega o último
/// `Result<T>`. `clearResult` zera para um próximo ciclo. Tentar
/// executar enquanto já roda é silenciosamente ignorado (re-entrancy
/// guard).
abstract class Command<T> extends ChangeNotifier {
  bool _running = false;
  Result<T>? _result;

  bool get running => _running;
  Result<T>? get result => _result;
  bool get error => _result is Error<T>;
  bool get completed => _result is Ok<T>;

  void clearResult() {
    _result = null;
    notifyListeners();
  }

  Future<void> _execute(Future<Result<T>> Function() action) async {
    if (_running) return;
    _running = true;
    _result = null;
    notifyListeners();
    try {
      _result = await action();
    } finally {
      _running = false;
      notifyListeners();
    }
  }
}

class Command0<T> extends Command<T> {
  Command0(this._action);
  final Future<Result<T>> Function() _action;

  Future<void> execute() => _execute(_action);
}

class Command1<T, A> extends Command<T> {
  Command1(this._action);
  final Future<Result<T>> Function(A arg) _action;

  Future<void> execute(A arg) => _execute(() => _action(arg));
}
```

- [ ] **Step 2: Validar analyze**

Run: `cd C:/mamba_growth && flutter analyze lib/utils/command.dart`
Expected: "No issues found!"

- [ ] **Step 3: Commit**

```bash
git -C C:/mamba_growth add lib/utils/command.dart
git -C C:/mamba_growth commit -m "feat(utils): add Command0/Command1 with re-entrancy guard"
```

---

## Task 4: `AuthUser` domain model

**Files:**
- Create: `lib/domain/models/auth_user.dart`

- [ ] **Step 1: Implementar `lib/domain/models/auth_user.dart`**

```dart
import 'package:flutter/foundation.dart';

/// Representação imutável do usuário autenticado.
///
/// Não depende de `package:firebase_auth`. O repository traduz
/// `User` (Firebase) → [AuthUser] na borda do data layer.
@immutable
class AuthUser {
  const AuthUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
}
```

- [ ] **Step 2: Validar analyze**

Run: `cd C:/mamba_growth && flutter analyze lib/domain/models/auth_user.dart`
Expected: "No issues found!"

- [ ] **Step 3: Commit**

```bash
git -C C:/mamba_growth add lib/domain/models/auth_user.dart
git -C C:/mamba_growth commit -m "feat(domain): add immutable AuthUser model"
```

---

## Task 5: `AuthException` + mapeamento Firebase

**Files:**
- Create: `lib/domain/models/auth_exception.dart`

- [ ] **Step 1: Implementar `lib/domain/models/auth_exception.dart`**

```dart
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
```

- [ ] **Step 2: Validar analyze**

Run: `cd C:/mamba_growth && flutter analyze lib/domain/models/auth_exception.dart`
Expected: "No issues found!"

- [ ] **Step 3: Commit**

```bash
git -C C:/mamba_growth add lib/domain/models/auth_exception.dart
git -C C:/mamba_growth commit -m "feat(domain): add AuthException with Firebase code mapping"
```

---

## Task 6: Strings de l10n (en + pt)

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_pt.arb`

- [ ] **Step 1: Adicionar strings em `app_en.arb`**

Acrescentar antes do `}` final de `lib/l10n/app_en.arb` (não esquecer da vírgula após o último item existente):

```json
,
  "authSignInTitle": "Welcome back",
  "@authSignInTitle": { "description": "Auth bottom sheet title in sign-in mode." },
  "authSignUpTitle": "Create your account",
  "@authSignUpTitle": { "description": "Auth bottom sheet title in sign-up mode." },
  "authSignInSubtitle": "Sign in to continue your journey.",
  "@authSignInSubtitle": { "description": "Auth bottom sheet subtitle in sign-in mode." },
  "authSignUpSubtitle": "Start tracking with intention.",
  "@authSignUpSubtitle": { "description": "Auth bottom sheet subtitle in sign-up mode." },
  "authEmailLabel": "Email",
  "@authEmailLabel": { "description": "Email field label." },
  "authEmailHint": "you@email.com",
  "@authEmailHint": { "description": "Email field hint." },
  "authPasswordLabel": "Password",
  "@authPasswordLabel": { "description": "Password field label." },
  "authPasswordVisibilityShow": "Show password",
  "@authPasswordVisibilityShow": { "description": "Semantic label to show the password." },
  "authPasswordVisibilityHide": "Hide password",
  "@authPasswordVisibilityHide": { "description": "Semantic label to hide the password." },
  "authSubmitSignIn": "Sign in",
  "@authSubmitSignIn": { "description": "Submit button in sign-in mode." },
  "authSubmitSignUp": "Create account",
  "@authSubmitSignUp": { "description": "Submit button in sign-up mode." },
  "authContinueWithGoogle": "Continue with Google",
  "@authContinueWithGoogle": { "description": "Google sign-in button label." },
  "authDividerOr": "OR",
  "@authDividerOr": { "description": "Separator between Google and email/password." },
  "authToggleToSignUpPrompt": "Don't have an account?",
  "@authToggleToSignUpPrompt": { "description": "Prompt to switch to sign-up mode." },
  "authToggleToSignUpAction": "Create one",
  "@authToggleToSignUpAction": { "description": "Action label to switch to sign-up." },
  "authToggleToSignInPrompt": "Already have an account?",
  "@authToggleToSignInPrompt": { "description": "Prompt to switch to sign-in mode." },
  "authToggleToSignInAction": "Sign in",
  "@authToggleToSignInAction": { "description": "Action label to switch to sign-in." },
  "authErrorInvalidCredentials": "Invalid email or password.",
  "@authErrorInvalidCredentials": { "description": "Inline error for invalid credentials." },
  "authErrorEmailInUse": "An account already exists for this email.",
  "@authErrorEmailInUse": { "description": "Inline error when email is already used." },
  "authErrorWeakPassword": "Password must be at least 6 characters.",
  "@authErrorWeakPassword": { "description": "Inline error for weak password." },
  "authErrorUserDisabled": "This account has been disabled.",
  "@authErrorUserDisabled": { "description": "Inline error when user is disabled." },
  "authErrorNetwork": "No internet connection.",
  "@authErrorNetwork": { "description": "Inline error for network failure." },
  "authErrorTooManyRequests": "Too many attempts. Try again later.",
  "@authErrorTooManyRequests": { "description": "Inline error for rate limiting." },
  "authErrorGoogleSignInFailed": "Could not sign in with Google.",
  "@authErrorGoogleSignInFailed": { "description": "Inline error when Google sign-in fails." },
  "authErrorUnknown": "Something went wrong. Please try again.",
  "@authErrorUnknown": { "description": "Generic fallback inline error." },
  "homeWelcomeGreeting": "Welcome, {name}",
  "@homeWelcomeGreeting": {
    "description": "Greeting on the home placeholder. {name} is the display name or email.",
    "placeholders": { "name": { "type": "String" } }
  },
  "homeComingSoon": "Your home is coming soon.",
  "@homeComingSoon": { "description": "Subtitle on the home placeholder." },
  "homeSignOut": "Sign out",
  "@homeSignOut": { "description": "Sign out button label." }
```

- [ ] **Step 2: Adicionar strings em `app_pt.arb`**

Acrescentar antes do `}` final de `lib/l10n/app_pt.arb`:

```json
,
  "authSignInTitle": "Bem-vindo de volta",
  "authSignUpTitle": "Crie sua conta",
  "authSignInSubtitle": "Entre para continuar sua jornada.",
  "authSignUpSubtitle": "Comece a acompanhar com intenção.",
  "authEmailLabel": "E-mail",
  "authEmailHint": "voce@email.com",
  "authPasswordLabel": "Senha",
  "authPasswordVisibilityShow": "Mostrar senha",
  "authPasswordVisibilityHide": "Ocultar senha",
  "authSubmitSignIn": "Entrar",
  "authSubmitSignUp": "Criar conta",
  "authContinueWithGoogle": "Continuar com Google",
  "authDividerOr": "OU",
  "authToggleToSignUpPrompt": "Não tem uma conta?",
  "authToggleToSignUpAction": "Criar agora",
  "authToggleToSignInPrompt": "Já tem uma conta?",
  "authToggleToSignInAction": "Entrar",
  "authErrorInvalidCredentials": "E-mail ou senha incorretos.",
  "authErrorEmailInUse": "Já existe uma conta com esse e-mail.",
  "authErrorWeakPassword": "A senha precisa ter no mínimo 6 caracteres.",
  "authErrorUserDisabled": "Esta conta foi desativada.",
  "authErrorNetwork": "Sem conexão com a internet.",
  "authErrorTooManyRequests": "Muitas tentativas. Tente novamente em instantes.",
  "authErrorGoogleSignInFailed": "Não foi possível entrar com Google.",
  "authErrorUnknown": "Algo deu errado. Tente novamente.",
  "homeWelcomeGreeting": "Olá, {name}",
  "homeComingSoon": "Sua tela inicial está chegando.",
  "homeSignOut": "Sair"
```

- [ ] **Step 3: Gerar localizations**

Run: `cd C:/mamba_growth && flutter gen-l10n`
Expected: regenera `lib/l10n/generated/app_localizations*.dart` sem erros.

- [ ] **Step 4: Validar analyze**

Run: `cd C:/mamba_growth && flutter analyze`
Expected: "No issues found!"

- [ ] **Step 5: Commit**

```bash
git -C C:/mamba_growth add lib/l10n/app_en.arb lib/l10n/app_pt.arb lib/l10n/generated
git -C C:/mamba_growth commit -m "feat(l10n): add auth and home placeholder strings (en, pt)"
```

---

## Task 7: `FirebaseAuthService` (wrap fino)

**Files:**
- Create: `lib/data/services/auth/firebase_auth_service.dart`

- [ ] **Step 1: Implementar `lib/data/services/auth/firebase_auth_service.dart`**

```dart
import 'package:firebase_auth/firebase_auth.dart';

/// Casca fina sobre [FirebaseAuth.instance].
///
/// Não tem estado, não tem regras. Existe para isolar o
/// `AuthRepository` da API do Firebase.
class FirebaseAuthService {
  FirebaseAuthService({FirebaseAuth? firebaseAuth})
      : _auth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  Future<UserCredential> signInWithCredential(AuthCredential credential) =>
      _auth.signInWithCredential(credential);

  Future<void> signOut() => _auth.signOut();
}
```

- [ ] **Step 2: Validar analyze**

Run: `cd C:/mamba_growth && flutter analyze lib/data/services/auth/firebase_auth_service.dart`
Expected: "No issues found!"

- [ ] **Step 3: Commit**

```bash
git -C C:/mamba_growth add lib/data/services/auth/firebase_auth_service.dart
git -C C:/mamba_growth commit -m "feat(data): add FirebaseAuthService wrapper"
```

---

## Task 8: `GoogleSignInService` (wrap 7.x)

**Files:**
- Create: `lib/data/services/auth/google_sign_in_service.dart`

- [ ] **Step 1: Implementar `lib/data/services/auth/google_sign_in_service.dart`**

```dart
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
```

- [ ] **Step 2: Validar analyze**

Run: `cd C:/mamba_growth && flutter analyze lib/data/services/auth/google_sign_in_service.dart`
Expected: "No issues found!"

- [ ] **Step 3: Commit**

```bash
git -C C:/mamba_growth add lib/data/services/auth/google_sign_in_service.dart
git -C C:/mamba_growth commit -m "feat(data): add GoogleSignInService wrapper (v7.x)"
```

---

## Task 9: `AuthRepository` abstract

**Files:**
- Create: `lib/data/repositories/auth/auth_repository.dart`

- [ ] **Step 1: Implementar `lib/data/repositories/auth/auth_repository.dart`**

```dart
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
```

- [ ] **Step 2: Validar analyze**

Run: `cd C:/mamba_growth && flutter analyze lib/data/repositories/auth/auth_repository.dart`
Expected: "No issues found!"

- [ ] **Step 3: Commit**

```bash
git -C C:/mamba_growth add lib/data/repositories/auth/auth_repository.dart
git -C C:/mamba_growth commit -m "feat(data): add AuthRepository abstract interface"
```

---

## Task 10: `AuthRepositoryFirebase`

**Files:**
- Create: `lib/data/repositories/auth/auth_repository_firebase.dart`

- [ ] **Step 1: Implementar `lib/data/repositories/auth/auth_repository_firebase.dart`**

```dart
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../domain/models/auth_exception.dart';
import '../../../domain/models/auth_user.dart';
import '../../../utils/result.dart';
import '../../services/auth/firebase_auth_service.dart';
import '../../services/auth/google_sign_in_service.dart';
import 'auth_repository.dart';

class AuthRepositoryFirebase extends AuthRepository {
  AuthRepositoryFirebase({
    required FirebaseAuthService firebaseAuthService,
    required GoogleSignInService googleSignInService,
  })  : _firebase = firebaseAuthService,
        _google = googleSignInService {
    _subscription = _firebase.authStateChanges().listen(_onAuthStateChanged);
  }

  final FirebaseAuthService _firebase;
  final GoogleSignInService _google;
  late final StreamSubscription<User?> _subscription;

  AuthUser? _currentUser;
  bool _isInitialized = false;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  bool get isInitialized => _isInitialized;

  void _onAuthStateChanged(User? user) {
    _currentUser = user == null ? null : _toAuthUser(user);
    _isInitialized = true;
    notifyListeners();
  }

  @override
  Future<Result<void>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _firebase.signInWithEmailAndPassword(email: email, password: password);
      return const Result.ok(null);
    } on FirebaseAuthException catch (e) {
      return Result.error(AuthException.fromFirebase(e));
    } on Exception catch (e) {
      return Result.error(AuthException.unknown(e));
    }
  }

  @override
  Future<Result<void>> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _firebase.createUserWithEmailAndPassword(email: email, password: password);
      return const Result.ok(null);
    } on FirebaseAuthException catch (e) {
      return Result.error(AuthException.fromFirebase(e));
    } on Exception catch (e) {
      return Result.error(AuthException.unknown(e));
    }
  }

  @override
  Future<Result<void>> signInWithGoogle() async {
    try {
      final idToken = await _google.authenticateAndGetIdToken();
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      await _firebase.signInWithCredential(credential);
      return const Result.ok(null);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return Result.error(const AuthCancelledException());
      }
      return Result.error(AuthException.googleSignInFailed(e));
    } on FirebaseAuthException catch (e) {
      return Result.error(AuthException.fromFirebase(e));
    } on Exception catch (e) {
      return Result.error(AuthException.unknown(e));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _google.signOut();
      await _firebase.signOut();
      return const Result.ok(null);
    } on Exception catch (e) {
      return Result.error(AuthException.unknown(e));
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  static AuthUser _toAuthUser(User u) => AuthUser(
        uid: u.uid,
        email: u.email ?? '',
        displayName: u.displayName,
        photoUrl: u.photoURL,
      );
}
```

- [ ] **Step 2: Validar analyze**

Run: `cd C:/mamba_growth && flutter analyze lib/data/repositories/auth/auth_repository_firebase.dart`
Expected: "No issues found!"

- [ ] **Step 3: Commit**

```bash
git -C C:/mamba_growth add lib/data/repositories/auth/auth_repository_firebase.dart
git -C C:/mamba_growth commit -m "feat(data): add AuthRepositoryFirebase with email/Google flows"
```

---

## Task 11: `AuthViewModel`

**Files:**
- Create: `lib/ui/auth/view_models/auth_view_model.dart`

- [ ] **Step 1: Implementar `lib/ui/auth/view_models/auth_view_model.dart`**

```dart
import 'package:flutter/foundation.dart';

import '../../../data/repositories/auth/auth_repository.dart';
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

  Future<Result<void>> _signInWithEmail(EmailPasswordInput input) =>
      _authRepository.signInWithEmail(email: input.email, password: input.password);

  Future<Result<void>> _signUpWithEmail(EmailPasswordInput input) =>
      _authRepository.signUpWithEmail(email: input.email, password: input.password);

  Future<Result<void>> _signInWithGoogle() => _authRepository.signInWithGoogle();
}
```

- [ ] **Step 2: Validar analyze**

Run: `cd C:/mamba_growth && flutter analyze lib/ui/auth/view_models/auth_view_model.dart`
Expected: "No issues found!"

- [ ] **Step 3: Commit**

```bash
git -C C:/mamba_growth add lib/ui/auth/view_models/auth_view_model.dart
git -C C:/mamba_growth commit -m "feat(ui): add AuthViewModel with signIn/signUp/Google commands"
```

---

## Task 12: Extrair `BrandMark` para `core/widgets`

**Files:**
- Create: `lib/ui/core/widgets/brand_mark.dart`
- Modify: `lib/ui/onboarding/widgets/onboarding_screen.dart` (remover classe privada `_BrandMark`, importar pública)

- [ ] **Step 1: Criar `lib/ui/core/widgets/brand_mark.dart`**

```dart
import 'package:flutter/material.dart';

import '../themes/themes.dart';

/// Brand mark padronizado: dot luminoso + nome em uppercase.
/// Usado no onboarding e no splash.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.accent,
            boxShadow: [
              BoxShadow(
                color: colors.accent.withValues(alpha: 0.6),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label.toUpperCase(),
          style: typo.caption.copyWith(
            color: colors.textDim,
            letterSpacing: 3.2,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Atualizar `lib/ui/onboarding/widgets/onboarding_screen.dart`**

a) Adicionar import (junto aos outros imports do arquivo):

```dart
import '../../core/widgets/brand_mark.dart';
```

b) Substituir o uso de `_BrandMark(label: l10n.appName)` (no método `build` do `_OnboardingScreenState`) por `BrandMark(label: l10n.appName)`.

c) Remover toda a classe privada `class _BrandMark extends StatelessWidget { ... }` no fim do arquivo.

- [ ] **Step 3: Validar analyze**

Run: `cd C:/mamba_growth && flutter analyze`
Expected: "No issues found!"

- [ ] **Step 4: Commit**

```bash
git -C C:/mamba_growth add lib/ui/core/widgets/brand_mark.dart lib/ui/onboarding/widgets/onboarding_screen.dart
git -C C:/mamba_growth commit -m "refactor(ui): extract BrandMark to core/widgets for reuse"
```

---

## Task 13: `SplashScreen`

**Files:**
- Create: `lib/ui/splash/widgets/splash_screen.dart`

- [ ] **Step 1: Implementar `lib/ui/splash/widgets/splash_screen.dart`**

```dart
import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../core/themes/themes.dart';
import '../../core/widgets/brand_mark.dart';

/// Tela de boot, exibida enquanto o `AuthRepository` ainda não recebeu
/// o primeiro evento de `authStateChanges`. Praticamente instantânea
/// em sessões persistidas.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BrandMark(label: l10n.appName),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(colors.accent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Validar analyze**

Run: `cd C:/mamba_growth && flutter analyze lib/ui/splash`
Expected: "No issues found!"

- [ ] **Step 3: Commit**

```bash
git -C C:/mamba_growth add lib/ui/splash/widgets/splash_screen.dart
git -C C:/mamba_growth commit -m "feat(ui): add SplashScreen used during auth boot"
```

---

## Task 14: `HomePlaceholderScreen`

**Files:**
- Create: `lib/ui/home/widgets/home_placeholder_screen.dart`

- [ ] **Step 1: Implementar `lib/ui/home/widgets/home_placeholder_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../core/themes/themes.dart';

/// Placeholder pós-login. Será substituído pela home real.
class HomePlaceholderScreen extends StatelessWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final l10n = AppLocalizations.of(context);
    final repo = context.watch<AuthRepository>();
    final user = repo.currentUser;
    final name = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : (user?.email ?? '');

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: Text(l10n.appName),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.homeWelcomeGreeting(name),
                textAlign: TextAlign.center,
                style: text.headlineSmall?.copyWith(color: colors.text),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.homeComingSoon,
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: colors.textDim),
              ),
              const SizedBox(height: AppSpacing.xl2),
              OutlinedButton.icon(
                onPressed: () async {
                  await repo.signOut();
                },
                icon: const Icon(Icons.logout),
                label: Text(l10n.homeSignOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Validar analyze**

Run: `cd C:/mamba_growth && flutter analyze lib/ui/home`
Expected: "No issues found!"

- [ ] **Step 3: Commit**

```bash
git -C C:/mamba_growth add lib/ui/home/widgets/home_placeholder_screen.dart
git -C C:/mamba_growth commit -m "feat(ui): add HomePlaceholderScreen with sign out"
```

---

## Task 15: `AuthBottomSheet`

**Files:**
- Create: `lib/ui/auth/widgets/auth_bottom_sheet.dart`

> Tarefa maior — sheet completo com drag handle, título/subtítulo dinâmicos, botão Google, divider OR, dois TextField, erro inline, submit CTA e toggle row.

- [ ] **Step 1: Implementar `lib/ui/auth/widgets/auth_bottom_sheet.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../domain/models/auth_exception.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';
import '../../core/themes/themes.dart';
import '../view_models/auth_view_model.dart';

class AuthBottomSheet extends StatelessWidget {
  const AuthBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: true,
      builder: (sheetContext) {
        return ChangeNotifierProvider<AuthViewModel>(
          create: (_) =>
              AuthViewModel(authRepository: context.read<AuthRepository>()),
          child: const AuthBottomSheet(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const _AuthSheetContent();
  }
}

class _AuthSheetContent extends StatefulWidget {
  const _AuthSheetContent();

  @override
  State<_AuthSheetContent> createState() => _AuthSheetContentState();
}

class _AuthSheetContentState extends State<_AuthSheetContent> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Command<void> _activeCommand(AuthViewModel vm) =>
      vm.mode == AuthMode.signIn ? vm.signInWithEmail : vm.signUpWithEmail;

  Future<void> _submit(AuthViewModel vm) async {
    final input = EmailPasswordInput(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    if (vm.mode == AuthMode.signIn) {
      await vm.signInWithEmail.execute(input);
    } else {
      await vm.signUpWithEmail.execute(input);
    }
    if (!mounted) return;
    final cmd = _activeCommand(vm);
    if (cmd.completed) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _submitGoogle(AuthViewModel vm) async {
    await vm.signInWithGoogle.execute();
    if (!mounted) return;
    if (vm.signInWithGoogle.completed) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final colors = context.colors;
    final text = context.text;
    final typo = context.typo;
    final l10n = AppLocalizations.of(context);
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;

    final isSignIn = vm.mode == AuthMode.signIn;
    final activeCmd = _activeCommand(vm);
    final googleCmd = vm.signInWithGoogle;

    final title = isSignIn ? l10n.authSignInTitle : l10n.authSignUpTitle;
    final subtitle = isSignIn ? l10n.authSignInSubtitle : l10n.authSignUpSubtitle;
    final ctaLabel = isSignIn ? l10n.authSubmitSignIn : l10n.authSubmitSignUp;
    final togglePrompt =
        isSignIn ? l10n.authToggleToSignUpPrompt : l10n.authToggleToSignInPrompt;
    final toggleAction =
        isSignIn ? l10n.authToggleToSignUpAction : l10n.authToggleToSignInAction;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                title,
                style: text.headlineSmall?.copyWith(color: colors.text),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle,
                style: text.bodyMedium?.copyWith(color: colors.textDim),
              ),
              const SizedBox(height: AppSpacing.xl),
              AnimatedBuilder(
                animation: Listenable.merge([activeCmd, googleCmd]),
                builder: (context, _) {
                  final running = activeCmd.running || googleCmd.running;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _GoogleButton(
                        label: l10n.authContinueWithGoogle,
                        running: googleCmd.running,
                        disabled: running,
                        onPressed: () => _submitGoogle(vm),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _OrDivider(label: l10n.authDividerOr),
                      const SizedBox(height: AppSpacing.lg),
                      _LabeledTextField(
                        label: l10n.authEmailLabel,
                        controller: _emailCtrl,
                        focusNode: _emailFocus,
                        hintText: l10n.authEmailHint,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        fieldKey: const Key('auth-email-field'),
                        enabled: !running,
                        onSubmitted: (_) => _passwordFocus.requestFocus(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _LabeledTextField(
                        label: l10n.authPasswordLabel,
                        controller: _passwordCtrl,
                        focusNode: _passwordFocus,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        autofillHints: isSignIn
                            ? const [AutofillHints.password]
                            : const [AutofillHints.newPassword],
                        fieldKey: const Key('auth-password-field'),
                        enabled: !running,
                        onSubmitted: (_) => _submit(vm),
                        suffixIcon: IconButton(
                          tooltip: _obscure
                              ? l10n.authPasswordVisibilityShow
                              : l10n.authPasswordVisibilityHide,
                          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _InlineError(command: activeCmd, l10n: l10n),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          key: const Key('auth-submit-button'),
                          onPressed: running ? null : () => _submit(vm),
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.accent,
                            foregroundColor: colors.bg,
                            disabledBackgroundColor:
                                colors.accent.withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                          ),
                          child: activeCmd.running
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation(colors.bg),
                                  ),
                                )
                              : Text(
                                  ctaLabel,
                                  style: text.labelLarge?.copyWith(
                                    color: colors.bg,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            togglePrompt,
                            style: text.bodySmall?.copyWith(color: colors.textDimmer),
                          ),
                          TextButton(
                            onPressed: running ? null : vm.toggleMode,
                            child: Text(toggleAction),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({
    required this.label,
    required this.running,
    required this.disabled,
    required this.onPressed,
  });

  final String label;
  final bool running;
  final bool disabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: disabled ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.text,
          side: BorderSide(color: colors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        child: running
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(colors.text),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'G',
                    style: text.labelLarge?.copyWith(
                      color: colors.text,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    label,
                    style: text.labelLarge?.copyWith(color: colors.text),
                  ),
                ],
              ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;

    return Row(
      children: [
        Expanded(child: Container(height: 1, color: colors.borderDim)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            label,
            style: typo.caption.copyWith(
              color: colors.textDimmer,
              letterSpacing: 2.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: colors.borderDim)),
      ],
    );
  }
}

class _LabeledTextField extends StatelessWidget {
  const _LabeledTextField({
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.fieldKey,
    this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscureText = false,
    this.suffixIcon,
    this.enabled = true,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final Key fieldKey;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final Widget? suffixIcon;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: typo.caption.copyWith(
            color: colors.textDim,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          key: fieldKey,
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          onSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: hintText,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.command, required this.l10n});

  final Command<void> command;
  final AppLocalizations l10n;

  String? _messageFor(Object error) {
    if (error is AuthCancelledException) return null;
    if (error is AuthException) {
      return switch (error.kind) {
        AuthErrorKind.invalidCredentials => l10n.authErrorInvalidCredentials,
        AuthErrorKind.emailAlreadyInUse => l10n.authErrorEmailInUse,
        AuthErrorKind.weakPassword => l10n.authErrorWeakPassword,
        AuthErrorKind.userDisabled => l10n.authErrorUserDisabled,
        AuthErrorKind.networkError => l10n.authErrorNetwork,
        AuthErrorKind.tooManyRequests => l10n.authErrorTooManyRequests,
        AuthErrorKind.googleSignInFailed => l10n.authErrorGoogleSignInFailed,
        AuthErrorKind.unknown => l10n.authErrorUnknown,
      };
    }
    return l10n.authErrorUnknown;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: command,
      builder: (context, _) {
        final result = command.result;
        final text = context.text;
        String? message;
        if (result is Error<void>) {
          message = _messageFor(result.error);
        }

        return AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: message == null
                ? const SizedBox(width: double.infinity)
                : Row(
                    key: const ValueKey('inline-error'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          message,
                          style: text.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 2: Validar analyze**

Run: `cd C:/mamba_growth && flutter analyze lib/ui/auth`
Expected: "No issues found!"

- [ ] **Step 3: Commit**

```bash
git -C C:/mamba_growth add lib/ui/auth/widgets/auth_bottom_sheet.dart
git -C C:/mamba_growth commit -m "feat(ui): add AuthBottomSheet with email/Google flows"
```

---

## Task 16: `Routes` constants

**Files:**
- Create: `lib/routing/routes.dart`

- [ ] **Step 1: Implementar `lib/routing/routes.dart`**

```dart
abstract class Routes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const home = '/home';
}

abstract class RouteNames {
  static const splash = 'splash';
  static const onboarding = 'onboarding';
  static const home = 'home';
}
```

- [ ] **Step 2: Validar analyze**

Run: `cd C:/mamba_growth && flutter analyze lib/routing/routes.dart`
Expected: "No issues found!"

- [ ] **Step 3: Commit**

```bash
git -C C:/mamba_growth add lib/routing/routes.dart
git -C C:/mamba_growth commit -m "feat(routing): add Routes and RouteNames constants"
```

---

## Task 17: `buildRouter` com redirect

**Files:**
- Create: `lib/routing/router.dart`

- [ ] **Step 1: Implementar `lib/routing/router.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../data/repositories/auth/auth_repository.dart';
import '../ui/auth/widgets/auth_bottom_sheet.dart';
import '../ui/home/widgets/home_placeholder_screen.dart';
import '../ui/onboarding/widgets/onboarding_screen.dart';
import '../ui/splash/widgets/splash_screen.dart';
import 'routes.dart';

GoRouter buildRouter({required AuthRepository authRepository}) {
  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: authRepository,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isInitialized = authRepository.isInitialized;
      final isAuthed = authRepository.isAuthenticated;

      if (!isInitialized) {
        return loc == Routes.splash ? null : Routes.splash;
      }

      if (isAuthed && (loc == Routes.splash || loc == Routes.onboarding)) {
        return Routes.home;
      }

      if (!isAuthed && (loc == Routes.splash || loc == Routes.home)) {
        return Routes.onboarding;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        name: RouteNames.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.onboarding,
        name: RouteNames.onboarding,
        builder: (context, _) {
          return OnboardingScreen(
            onContinue: () async {
              HapticFeedback.mediumImpact();
              await AuthBottomSheet.show(context);
            },
          );
        },
      ),
      GoRoute(
        path: Routes.home,
        name: RouteNames.home,
        builder: (_, __) => const HomePlaceholderScreen(),
      ),
    ],
  );
}
```

- [ ] **Step 2: Validar analyze**

Run: `cd C:/mamba_growth && flutter analyze lib/routing/router.dart`
Expected: "No issues found!"

- [ ] **Step 3: Commit**

```bash
git -C C:/mamba_growth add lib/routing/router.dart
git -C C:/mamba_growth commit -m "feat(routing): add GoRouter with auth-aware redirect"
```

---

## Task 18: Refatorar `main.dart` (bootstrap async + DI raiz)

**Files:**
- Modify: `lib/main.dart`
- Delete: `test/widget_test.dart` (template inicial referencia `MyApp` que não existe mais)

- [ ] **Step 1: Substituir conteúdo de `lib/main.dart`**

Substituir o arquivo inteiro por:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'data/repositories/auth/auth_repository.dart';
import 'data/repositories/auth/auth_repository_firebase.dart';
import 'data/services/auth/firebase_auth_service.dart';
import 'data/services/auth/google_sign_in_service.dart';
import 'firebase_options.dart';
import 'l10n/generated/app_localizations.dart';
import 'routing/router.dart';
import 'ui/core/themes/themes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firebaseAuthService = FirebaseAuthService();
  final googleSignInService = GoogleSignInService();
  final authRepository = AuthRepositoryFirebase(
    firebaseAuthService: firebaseAuthService,
    googleSignInService: googleSignInService,
  );

  runApp(MambaGrowthApp(authRepository: authRepository));
}

class MambaGrowthApp extends StatelessWidget {
  const MambaGrowthApp({super.key, required this.authRepository});

  final AuthRepository authRepository;

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthRepository>.value(
      value: authRepository,
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
        routerConfig: buildRouter(authRepository: authRepository),
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
```

> Removemos o import de `OnboardingScreen` e o uso direto em `home`. O router agora é responsável.

- [ ] **Step 2: Deletar `test/widget_test.dart`**

Run: `rm C:/mamba_growth/test/widget_test.dart`
Expected: arquivo removido. (Sem testes neste MVP — o template original referencia `MyApp` que não existe mais.)

- [ ] **Step 3: Validar analyze**

Run: `cd C:/mamba_growth && flutter analyze`
Expected: "No issues found!"

- [ ] **Step 4: Commit**

```bash
git -C C:/mamba_growth add lib/main.dart
git -C C:/mamba_growth rm test/widget_test.dart
git -C C:/mamba_growth commit -m "feat(app): wire async bootstrap, DI root and router"
```

---

## Task 19: Configuração nativa Android

**Files:**
- Modify (se necessário): `android/build.gradle` ou `android/build.gradle.kts`
- Modify (se necessário): `android/app/build.gradle` ou `android/app/build.gradle.kts`

- [ ] **Step 1: Inspecionar arquivos Gradle**

Run: `cd C:/mamba_growth && ls android/ && ls android/app/`
Expected: ver se são `.gradle` (Groovy) ou `.gradle.kts` (Kotlin DSL).

- [ ] **Step 2: Garantir plugin Google Services no project-level**

Ler `android/build.gradle` (Groovy) ou `android/build.gradle.kts` (KTS) e `android/settings.gradle*`.

Se for Groovy (`build.gradle`) e o classpath não contiver `com.google.gms:google-services`, adicionar dentro de `buildscript.dependencies`:

```groovy
classpath 'com.google.gms:google-services:4.4.2'
```

Se for Kotlin DSL e o id `com.google.gms.google-services` não estiver em `settings.gradle.kts` `pluginManagement` ou em `build.gradle.kts` `plugins`, adicionar em `android/settings.gradle.kts`:

```kotlin
plugins {
    id("com.google.gms.google-services") version "4.4.2" apply false
}
```

- [ ] **Step 3: Garantir plugin aplicado no app-level**

Em `android/app/build.gradle` (Groovy) — adicionar no topo se ausente:

```groovy
apply plugin: 'com.google.gms.google-services'
```

Em `android/app/build.gradle.kts` — adicionar no bloco `plugins` se ausente:

```kotlin
id("com.google.gms.google-services")
```

- [ ] **Step 4: Verificar minSdk**

Em `android/app/build.gradle*`, garantir `minSdkVersion 23` (Groovy) ou `minSdk = 23` (KTS). Subir para 23 se estiver menor.

- [ ] **Step 5: Build Android**

Run: `cd C:/mamba_growth && flutter build apk --debug`
Expected: build succeeds. Se faltar plugin, aplicar correção e re-rodar.

- [ ] **Step 6: Commit (somente se houver mudança)**

```bash
git -C C:/mamba_growth status --short
# Se houver arquivos modificados em android/:
git -C C:/mamba_growth add android/
git -C C:/mamba_growth commit -m "chore(android): apply google-services plugin and bump minSdk"
```

> Se nenhum arquivo precisou ser alterado, pular o commit.

---

## Task 20: Configuração iOS (verificação + doc)

**Files:**
- Modify (se ambiente macOS): `ios/Runner/Info.plist`
- Create (caso ambiente Windows): `docs/superpowers/notes/2026-04-28-ios-followup.md`

> Build e teste real do iOS exigem macOS. Este projeto roda em Windows. A task documenta o follow-up.

- [ ] **Step 1: Verificar presença de `GoogleService-Info.plist`**

Run: `ls C:/mamba_growth/ios/Runner/GoogleService-Info.plist 2>/dev/null && echo OK || echo MISSING`
Expected: `OK` (Firebase config presente). Se MISSING, fica como follow-up no doc.

- [ ] **Step 2: Criar `docs/superpowers/notes/2026-04-28-ios-followup.md`**

```markdown
# iOS follow-up — Firebase Auth

Verificar/aplicar quando estiver em ambiente macOS:

1. Abrir `ios/Runner.xcworkspace` no Xcode.
2. Confirmar que `GoogleService-Info.plist` está no target Runner.
3. Em `ios/Runner/Info.plist`, garantir bloco `CFBundleURLTypes` com o `REVERSED_CLIENT_ID` do Firebase como URL scheme:

   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleTypeRole</key>
       <string>Editor</string>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>{{REVERSED_CLIENT_ID}}</string>
       </array>
     </dict>
   </array>
   ```

   Substituir `{{REVERSED_CLIENT_ID}}` pelo valor do campo homônimo do `GoogleService-Info.plist`.

4. Garantir `platform :ios, '13.0'` no `ios/Podfile`.
5. Rodar `cd ios && pod install`.
6. `flutter run -d <ios-device>` e validar:
   - Sign in com email/senha.
   - Sign in com Google (tela do Google deve aparecer).
   - Sign out volta para onboarding.
```

- [ ] **Step 3: Commit do doc**

```bash
git -C C:/mamba_growth add docs/superpowers/notes/2026-04-28-ios-followup.md
git -C C:/mamba_growth commit -m "docs(ios): note Firebase Auth iOS follow-up steps"
```

---

## Task 21: Console Firebase (manual — não-código)

**Files:** nenhum.

> Esta task é uma checagem manual via Firebase Console. Sem código, sem commit. Apenas registro.

- [ ] **Step 1: Habilitar provider Email/Password**

Acessar https://console.firebase.google.com → projeto `mamba-growth-kn` → Authentication → Sign-in method → Email/Password → **Enable** → Save.

- [ ] **Step 2: Habilitar provider Google**

Mesma tela → Google → Enable → preencher e-mail de suporte do projeto → Save.

- [ ] **Step 3: Confirmar conclusão com o usuário**

Pedir confirmação ao usuário antes de prosseguir para o smoke test.

---

## Task 22: Smoke test end-to-end (manual)

**Files:** nenhum.

> Validar acceptance criteria do spec §11.

- [ ] **Step 1: Executar app em dispositivo Android**

Run: `cd C:/mamba_growth && flutter run -d <android-device-id>`

- [ ] **Step 2: Validar checklist do spec**

Marcar manualmente cada item de §11 do spec:

- [ ] `flutter analyze` passa.
- [ ] App instala e roda no Android.
- [ ] Sign in com email/senha funciona contra usuário criado no console.
- [ ] Sign up cria usuário; após criação, vai para `/home`.
- [ ] Sign in com Google funciona (Android com Play Services).
- [ ] Sign out na home volta para `/onboarding`.
- [ ] Reabrir app com sessão ativa → vai direto para `/home` (sem onboarding).
- [ ] Erro de credencial inválida aparece inline no sheet.
- [ ] Cancelar Google Sign-In não mostra erro.
- [ ] Cores/typo/spacing 100% via design system.

- [ ] **Step 3: Comunicar conclusão**

Reportar resultado do smoke test ao usuário.

---

## Self-review

### Spec coverage
- §1 Goal → Tasks 1–18 cobrem; §22 valida manualmente.
- §2 Non-goals → respeitados (sem forgot/verify/freezed/use cases/testes — testes pulados a pedido do usuário).
- §3 Architecture → Tasks 2–11.
- §4 File layout → Tasks 1–18 (todos os arquivos criados/modificados).
- §5 Detailed design → Tasks 2–18 cobrem cada subseção.
- §6 Dependencies → Task 1 (sem `mocktail`).
- §7 Native config → Tasks 19–20.
- §8 Localization → Task 6.
- §9 Testing strategy → **Pulado por decisão do usuário.** Documentado no header do plano.
- §10 Risks → mitigations distribuídas (botão Google fica desabilitado quando `running` na Task 15; splash on initial location na Task 17; viewInsets na Task 15).
- §11 Acceptance criteria → Task 22 (sem item de `flutter test`).
- §12 Out of scope → respeitado.

### Placeholder scan
Sem TBD/TODO funcionais. `{{REVERSED_CLIENT_ID}}` no doc iOS é placeholder legítimo de configuração.

### Type consistency
- `Result<T>`, `Ok<T>`, `Error<T>` consistentes entre Tasks 2, 10, 15.
- `AuthErrorKind` cases enumerados em Task 5 e referenciados exatamente em Task 15 (switch exaustivo).
- `Command0`/`Command1` API (`execute`, `running`, `result`, `error`, `completed`, `clearResult`) idêntica entre Tasks 3, 11, 15.
- `AuthRepository` interface (`currentUser`, `isAuthenticated`, `isInitialized`, 4 métodos `Future<Result<void>>`) idêntica nos consumidores das Tasks 11, 14, 15, 17, 18.
- `EmailPasswordInput({email, password})` consistente entre Tasks 11 e 15.
