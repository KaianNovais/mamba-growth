# Firebase Auth Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Adicionar autenticação Firebase (email/senha + Google) com bottom sheet aberto pelo CTA "Start" do onboarding, sessão persistida e roteamento via `go_router` baseado no estado de auth.

**Architecture:** MVVM + Repository + Service do skill `flutter-expert` (case study Compass do time Flutter), com `ChangeNotifier` + `provider`. `AuthRepository` é a SSOT do `currentUser` e dispara o redirect do `GoRouter` via `refreshListenable`. `Result<T>` na borda repo→viewmodel; UI consome `Command0/Command1`. Design system de `lib/ui/core/themes` é única fonte de verdade.

**Tech Stack:** Flutter 3.11+, Dart 3, `firebase_auth ^6.4.0`, `google_sign_in ^7.2.0`, `go_router ^16.3.0`, `provider ^6.1.5`, `mocktail ^1.0.4` (dev).

**Spec:** `docs/superpowers/specs/2026-04-28-firebase-auth-design.md`

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
| `test/utils/result_test.dart` | Testes do Result. |
| `test/utils/command_test.dart` | Testes dos commands. |
| `test/domain/models/auth_exception_test.dart` | Mapeamento `FirebaseAuthException.code` → `AuthErrorKind`. |
| `test/data/repositories/auth/auth_repository_firebase_test.dart` | Testes do repo (sucesso, erro, cancel, signOut, authStateChanges). |
| `test/ui/auth/view_models/auth_view_model_test.dart` | Testes do VM (toggleMode, commands, re-entrancy). |
| `test/ui/auth/widgets/auth_bottom_sheet_test.dart` | Widget tests do sheet. |
| `test/routing/router_test.dart` | Matrix de redirect. |

### Modified files

| Path | Mudança |
|---|---|
| `pubspec.yaml` | Adicionar 4 deps. |
| `lib/main.dart` | Bootstrap async com `Firebase.initializeApp`, DI raiz, `MaterialApp.router`. |
| `lib/ui/onboarding/widgets/onboarding_screen.dart` | Remover `_BrandMark` privado (movido para core/widgets). |
| `lib/l10n/app_en.arb` | +27 strings. |
| `lib/l10n/app_pt.arb` | +27 strings. |
| `android/build.gradle` (se necessário) | Plugin `com.google.gms.google-services` no classpath. |
| `android/app/build.gradle` (se necessário) | Aplicar plugin `com.google.gms.google-services`. |

---

## Conventions

- **Test runner:** `flutter test`. Para um arquivo: `flutter test test/<path>.dart`. Para um nome específico: `flutter test test/<path>.dart --plain-name "<test name>"`.
- **Static analysis:** `flutter analyze` (zero issues exigidos).
- **Codegen l10n:** `flutter gen-l10n` (executa baseado em `l10n.yaml`).
- **Commits:** Conventional Commits (`feat:`, `test:`, `refactor:`, `chore:`, `docs:`). Cada task termina em commit.
- **Mocking:** `mocktail` (sem code-gen). Fakes via `class FakeFoo extends Mock implements Foo`.
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

dev_dependencies:
  flutter_test:
    sdk: flutter

  flutter_lints: ^6.0.0
  flutter_launcher_icons: ^0.14.4
  mocktail: ^1.0.4
```

- [ ] **Step 2: Resolver pacotes**

Run: `cd C:/mamba_growth && flutter pub get`
Expected: "Got dependencies!" sem conflito de versões.

- [ ] **Step 3: Validar analyze**

Run: `cd C:/mamba_growth && flutter analyze`
Expected: "No issues found!"

- [ ] **Step 4: Commit**

```bash
git -C C:/mamba_growth add pubspec.yaml pubspec.lock
git -C C:/mamba_growth commit -m "chore(deps): add google_sign_in, go_router, provider, mocktail"
```

---

## Task 2: `Result<T>` sealed class

**Files:**
- Create: `lib/utils/result.dart`
- Test: `test/utils/result_test.dart`

- [ ] **Step 1: Escrever o teste falhando**

Conteúdo de `test/utils/result_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mamba_growth/utils/result.dart';

void main() {
  group('Result', () {
    test('Ok carries the value', () {
      const result = Result<int>.ok(42);

      expect(result, isA<Ok<int>>());
      expect((result as Ok<int>).value, 42);
    });

    test('Error carries the exception', () {
      final exception = Exception('boom');
      final result = Result<int>.error(exception);

      expect(result, isA<Error<int>>());
      expect((result as Error<int>).error, exception);
    });

    test('pattern match works for Ok and Error', () {
      Result<String> r1 = const Result.ok('hello');
      Result<String> r2 = Result.error(Exception('nope'));

      String describe(Result<String> r) => switch (r) {
        Ok(:final value) => 'ok=$value',
        Error(:final error) => 'err=$error',
      };

      expect(describe(r1), 'ok=hello');
      expect(describe(r2), startsWith('err=Exception'));
    });
  });
}
```

- [ ] **Step 2: Rodar teste — esperar falha por arquivo inexistente**

Run: `cd C:/mamba_growth && flutter test test/utils/result_test.dart`
Expected: Compile error (`result.dart` não existe).

- [ ] **Step 3: Implementar `lib/utils/result.dart`**

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

- [ ] **Step 4: Rodar teste — esperar verde**

Run: `cd C:/mamba_growth && flutter test test/utils/result_test.dart`
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git -C C:/mamba_growth add lib/utils/result.dart test/utils/result_test.dart
git -C C:/mamba_growth commit -m "feat(utils): add sealed Result<T> with Ok/Error"
```

---

## Task 3: `Command0` / `Command1`

**Files:**
- Create: `lib/utils/command.dart`
- Test: `test/utils/command_test.dart`

- [ ] **Step 1: Escrever o teste falhando**

Conteúdo de `test/utils/command_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mamba_growth/utils/command.dart';
import 'package:mamba_growth/utils/result.dart';

void main() {
  group('Command0', () {
    test('runs action and exposes Ok result', () async {
      final cmd = Command0<String>(() async => const Result.ok('done'));
      var notifications = 0;
      cmd.addListener(() => notifications++);

      await cmd.execute();

      expect(cmd.completed, isTrue);
      expect(cmd.error, isFalse);
      expect(cmd.running, isFalse);
      expect((cmd.result! as Ok<String>).value, 'done');
      expect(notifications, greaterThanOrEqualTo(2)); // start + finish
    });

    test('runs action and exposes Error result', () async {
      final cmd = Command0<void>(() async => Result.error(Exception('x')));

      await cmd.execute();

      expect(cmd.error, isTrue);
      expect(cmd.completed, isFalse);
    });

    test('re-entrancy guard ignores second execute while running', () async {
      var calls = 0;
      final cmd = Command0<void>(() async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return const Result.ok(null);
      });

      final first = cmd.execute();
      await cmd.execute(); // deve ser ignorada
      await first;

      expect(calls, 1);
    });

    test('clearResult resets state and notifies', () async {
      final cmd = Command0<int>(() async => const Result.ok(7));
      await cmd.execute();
      expect(cmd.completed, isTrue);

      var notified = false;
      cmd.addListener(() => notified = true);
      cmd.clearResult();

      expect(cmd.result, isNull);
      expect(notified, isTrue);
    });
  });

  group('Command1', () {
    test('passes argument to action', () async {
      final cmd = Command1<int, int>((a) async => Result.ok(a * 2));

      await cmd.execute(21);

      expect((cmd.result! as Ok<int>).value, 42);
    });
  });
}
```

- [ ] **Step 2: Rodar teste — esperar falha**

Run: `cd C:/mamba_growth && flutter test test/utils/command_test.dart`
Expected: Compile error (arquivo não existe).

- [ ] **Step 3: Implementar `lib/utils/command.dart`**

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

- [ ] **Step 4: Rodar teste — esperar verde**

Run: `cd C:/mamba_growth && flutter test test/utils/command_test.dart`
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git -C C:/mamba_growth add lib/utils/command.dart test/utils/command_test.dart
git -C C:/mamba_growth commit -m "feat(utils): add Command0/Command1 with re-entrancy guard"
```

---

## Task 4: `AuthUser` domain model

**Files:**
- Create: `lib/domain/models/auth_user.dart`

Sem teste — value class trivial.

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
- Test: `test/domain/models/auth_exception_test.dart`

- [ ] **Step 1: Escrever o teste falhando**

Conteúdo de `test/domain/models/auth_exception_test.dart`:

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamba_growth/domain/models/auth_exception.dart';

void main() {
  group('AuthException.fromFirebase', () {
    AuthException map(String code) =>
        AuthException.fromFirebase(FirebaseAuthException(code: code));

    test('maps invalid-credential to invalidCredentials', () {
      expect(map('invalid-credential').kind, AuthErrorKind.invalidCredentials);
    });

    test('maps invalid-email to invalidCredentials', () {
      expect(map('invalid-email').kind, AuthErrorKind.invalidCredentials);
    });

    test('maps wrong-password to invalidCredentials', () {
      expect(map('wrong-password').kind, AuthErrorKind.invalidCredentials);
    });

    test('maps user-not-found to invalidCredentials', () {
      expect(map('user-not-found').kind, AuthErrorKind.invalidCredentials);
    });

    test('maps email-already-in-use to emailAlreadyInUse', () {
      expect(map('email-already-in-use').kind, AuthErrorKind.emailAlreadyInUse);
    });

    test('maps weak-password to weakPassword', () {
      expect(map('weak-password').kind, AuthErrorKind.weakPassword);
    });

    test('maps user-disabled to userDisabled', () {
      expect(map('user-disabled').kind, AuthErrorKind.userDisabled);
    });

    test('maps network-request-failed to networkError', () {
      expect(map('network-request-failed').kind, AuthErrorKind.networkError);
    });

    test('maps too-many-requests to tooManyRequests', () {
      expect(map('too-many-requests').kind, AuthErrorKind.tooManyRequests);
    });

    test('falls back to unknown for unrecognized codes', () {
      expect(map('something-weird').kind, AuthErrorKind.unknown);
    });

    test('preserves original FirebaseAuthException as cause', () {
      final fbException = FirebaseAuthException(code: 'invalid-credential');
      final mapped = AuthException.fromFirebase(fbException);
      expect(mapped.cause, fbException);
    });
  });

  test('AuthCancelledException is a distinct type', () {
    expect(const AuthCancelledException(), isA<Exception>());
    expect(const AuthCancelledException(), isNot(isA<AuthException>()));
  });
}
```

- [ ] **Step 2: Rodar teste — esperar falha**

Run: `cd C:/mamba_growth && flutter test test/domain/models/auth_exception_test.dart`
Expected: Compile error.

- [ ] **Step 3: Implementar `lib/domain/models/auth_exception.dart`**

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

- [ ] **Step 4: Rodar teste — esperar verde**

Run: `cd C:/mamba_growth && flutter test test/domain/models/auth_exception_test.dart`
Expected: `All tests passed!` (11 tests).

- [ ] **Step 5: Commit**

```bash
git -C C:/mamba_growth add lib/domain/models/auth_exception.dart test/domain/models/auth_exception_test.dart
git -C C:/mamba_growth commit -m "feat(domain): add AuthException with Firebase code mapping"
```

---

## Task 6: Strings de l10n (en + pt)

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_pt.arb`

- [ ] **Step 1: Adicionar strings em `app_en.arb`**

Acrescentar antes do `}` final de `lib/l10n/app_en.arb`:

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

Acrescentar antes do `}` final de `lib/l10n/app_pt.arb` (mesma ordem, traduções pt-BR):

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

> Nota: o `app_pt.arb` é o secondary locale e por convenção do `intl` não precisa de blocos `@keyName` (eles ficam no template `app_en.arb`).

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

Sem teste — wrapper sem lógica. Será exercitado pelos testes do repository.

- [ ] **Step 1: Implementar `lib/data/services/auth/firebase_auth_service.dart`**

```dart
import 'package:firebase_auth/firebase_auth.dart';

/// Casca fina sobre [FirebaseAuth.instance].
///
/// Não tem estado, não tem regras. Existe para que o
/// `AuthRepository` seja testável (a gente fakea esta classe).
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

## Task 10: `AuthRepositoryFirebase` + testes

**Files:**
- Create: `lib/data/repositories/auth/auth_repository_firebase.dart`
- Test: `test/data/repositories/auth/auth_repository_firebase_test.dart`

- [ ] **Step 1: Escrever o teste falhando**

Conteúdo de `test/data/repositories/auth/auth_repository_firebase_test.dart`:

```dart
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mamba_growth/data/repositories/auth/auth_repository_firebase.dart';
import 'package:mamba_growth/data/services/auth/firebase_auth_service.dart';
import 'package:mamba_growth/data/services/auth/google_sign_in_service.dart';
import 'package:mamba_growth/domain/models/auth_exception.dart';
import 'package:mamba_growth/utils/result.dart';
import 'package:mocktail/mocktail.dart';

class _FakeFirebaseAuthService extends Mock implements FirebaseAuthService {}

class _FakeGoogleSignInService extends Mock implements GoogleSignInService {}

class _FakeUser extends Mock implements User {}

class _FakeUserCredential extends Mock implements UserCredential {}

class _FakeAuthCredential extends Mock implements AuthCredential {}

void main() {
  late _FakeFirebaseAuthService firebase;
  late _FakeGoogleSignInService google;
  late StreamController<User?> authStream;

  setUpAll(() {
    registerFallbackValue(_FakeAuthCredential());
  });

  setUp(() {
    firebase = _FakeFirebaseAuthService();
    google = _FakeGoogleSignInService();
    authStream = StreamController<User?>.broadcast();
    when(() => firebase.authStateChanges())
        .thenAnswer((_) => authStream.stream);
  });

  tearDown(() async {
    await authStream.close();
  });

  AuthRepositoryFirebase build() => AuthRepositoryFirebase(
        firebaseAuthService: firebase,
        googleSignInService: google,
      );

  test('signInWithEmail success returns Ok', () async {
    when(() => firebase.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => _FakeUserCredential());

    final repo = build();
    final result = await repo.signInWithEmail(email: 'a@b.c', password: 'pw');

    expect(result, isA<Ok<void>>());
    verify(() => firebase.signInWithEmailAndPassword(
          email: 'a@b.c',
          password: 'pw',
        )).called(1);
  });

  test('signInWithEmail maps invalid-credential FirebaseAuthException', () async {
    when(() => firebase.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(FirebaseAuthException(code: 'invalid-credential'));

    final repo = build();
    final result = await repo.signInWithEmail(email: 'a@b.c', password: 'pw');

    expect(result, isA<Error<void>>());
    final err = (result as Error<void>).error;
    expect(err, isA<AuthException>());
    expect((err as AuthException).kind, AuthErrorKind.invalidCredentials);
  });

  test('signUpWithEmail maps email-already-in-use', () async {
    when(() => firebase.createUserWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

    final repo = build();
    final result = await repo.signUpWithEmail(email: 'a@b.c', password: 'pw');

    expect(result, isA<Error<void>>());
    expect(
      ((result as Error<void>).error as AuthException).kind,
      AuthErrorKind.emailAlreadyInUse,
    );
  });

  test('signInWithGoogle success calls authenticate then signInWithCredential', () async {
    when(() => google.authenticateAndGetIdToken()).thenAnswer((_) async => 'tok');
    when(() => firebase.signInWithCredential(any()))
        .thenAnswer((_) async => _FakeUserCredential());

    final repo = build();
    final result = await repo.signInWithGoogle();

    expect(result, isA<Ok<void>>());
    verifyInOrder([
      () => google.authenticateAndGetIdToken(),
      () => firebase.signInWithCredential(any()),
    ]);
  });

  test('signInWithGoogle cancellation returns Error<AuthCancelledException>', () async {
    when(() => google.authenticateAndGetIdToken())
        .thenThrow(const GoogleSignInException(
          code: GoogleSignInExceptionCode.canceled,
          description: 'User canceled',
        ));

    final repo = build();
    final result = await repo.signInWithGoogle();

    expect(result, isA<Error<void>>());
    expect((result as Error<void>).error, isA<AuthCancelledException>());
  });

  test('authStateChanges propagates currentUser and notifies listeners', () async {
    final repo = build();
    var notifications = 0;
    repo.addListener(() => notifications++);

    expect(repo.isInitialized, isFalse);
    expect(repo.currentUser, isNull);

    final user = _FakeUser();
    when(() => user.uid).thenReturn('u1');
    when(() => user.email).thenReturn('a@b.c');
    when(() => user.displayName).thenReturn('Kaian');
    when(() => user.photoURL).thenReturn(null);

    authStream.add(user);
    await Future<void>.delayed(Duration.zero);

    expect(repo.isInitialized, isTrue);
    expect(repo.currentUser, isNotNull);
    expect(repo.currentUser!.uid, 'u1');
    expect(repo.isAuthenticated, isTrue);
    expect(notifications, greaterThanOrEqualTo(1));

    authStream.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(repo.currentUser, isNull);
    expect(repo.isAuthenticated, isFalse);
  });

  test('signOut calls google then firebase', () async {
    when(() => google.signOut()).thenAnswer((_) async {});
    when(() => firebase.signOut()).thenAnswer((_) async {});

    final repo = build();
    final result = await repo.signOut();

    expect(result, isA<Ok<void>>());
    verifyInOrder([
      () => google.signOut(),
      () => firebase.signOut(),
    ]);
  });
}
```

- [ ] **Step 2: Rodar teste — esperar falha**

Run: `cd C:/mamba_growth && flutter test test/data/repositories/auth/auth_repository_firebase_test.dart`
Expected: Compile error.

- [ ] **Step 3: Implementar `lib/data/repositories/auth/auth_repository_firebase.dart`**

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

- [ ] **Step 4: Rodar teste — esperar verde**

Run: `cd C:/mamba_growth && flutter test test/data/repositories/auth/auth_repository_firebase_test.dart`
Expected: `All tests passed!` (7 tests).

- [ ] **Step 5: Commit**

```bash
git -C C:/mamba_growth add lib/data/repositories/auth/auth_repository_firebase.dart test/data/repositories/auth/auth_repository_firebase_test.dart
git -C C:/mamba_growth commit -m "feat(data): add AuthRepositoryFirebase with email/Google flows"
```

---

## Task 11: `AuthViewModel` + testes

**Files:**
- Create: `lib/ui/auth/view_models/auth_view_model.dart`
- Test: `test/ui/auth/view_models/auth_view_model_test.dart`

- [ ] **Step 1: Escrever o teste falhando**

Conteúdo de `test/ui/auth/view_models/auth_view_model_test.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamba_growth/data/repositories/auth/auth_repository.dart';
import 'package:mamba_growth/domain/models/auth_user.dart';
import 'package:mamba_growth/ui/auth/view_models/auth_view_model.dart';
import 'package:mamba_growth/utils/result.dart';
import 'package:mocktail/mocktail.dart';

class _FakeAuthRepository extends ChangeNotifier implements AuthRepository {
  Future<Result<void>> signInResponse = Future.value(const Result.ok(null));
  Future<Result<void>> signUpResponse = Future.value(const Result.ok(null));
  Future<Result<void>> googleResponse = Future.value(const Result.ok(null));

  int signInCalls = 0;
  int signUpCalls = 0;
  int googleCalls = 0;

  @override
  AuthUser? get currentUser => null;

  @override
  bool get isAuthenticated => false;

  @override
  bool get isInitialized => true;

  @override
  Future<Result<void>> signInWithEmail({required String email, required String password}) {
    signInCalls++;
    return signInResponse;
  }

  @override
  Future<Result<void>> signUpWithEmail({required String email, required String password}) {
    signUpCalls++;
    return signUpResponse;
  }

  @override
  Future<Result<void>> signInWithGoogle() {
    googleCalls++;
    return googleResponse;
  }

  @override
  Future<Result<void>> signOut() async => const Result.ok(null);
}

void main() {
  late _FakeAuthRepository repo;

  setUp(() {
    repo = _FakeAuthRepository();
  });

  test('starts in signIn mode', () {
    final vm = AuthViewModel(authRepository: repo);
    expect(vm.mode, AuthMode.signIn);
  });

  test('toggleMode flips mode and notifies', () {
    final vm = AuthViewModel(authRepository: repo);
    var notified = false;
    vm.addListener(() => notified = true);

    vm.toggleMode();

    expect(vm.mode, AuthMode.signUp);
    expect(notified, isTrue);

    vm.toggleMode();
    expect(vm.mode, AuthMode.signIn);
  });

  test('toggleMode clears previous results from email commands', () async {
    final vm = AuthViewModel(authRepository: repo);

    await vm.signInWithEmail.execute(
      const EmailPasswordInput(email: 'a@b.c', password: 'pw'),
    );
    expect(vm.signInWithEmail.completed, isTrue);

    vm.toggleMode();

    expect(vm.signInWithEmail.result, isNull);
    expect(vm.signUpWithEmail.result, isNull);
  });

  test('signInWithEmail.execute calls repository signInWithEmail', () async {
    final vm = AuthViewModel(authRepository: repo);

    await vm.signInWithEmail.execute(
      const EmailPasswordInput(email: 'a@b.c', password: 'pw'),
    );

    expect(repo.signInCalls, 1);
    expect(vm.signInWithEmail.completed, isTrue);
  });

  test('signInWithGoogle.execute calls repository signInWithGoogle', () async {
    final vm = AuthViewModel(authRepository: repo);

    await vm.signInWithGoogle.execute();

    expect(repo.googleCalls, 1);
  });
}
```

- [ ] **Step 2: Rodar teste — esperar falha**

Run: `cd C:/mamba_growth && flutter test test/ui/auth/view_models/auth_view_model_test.dart`
Expected: Compile error.

- [ ] **Step 3: Implementar `lib/ui/auth/view_models/auth_view_model.dart`**

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

- [ ] **Step 4: Rodar teste — esperar verde**

Run: `cd C:/mamba_growth && flutter test test/ui/auth/view_models/auth_view_model_test.dart`
Expected: `All tests passed!` (5 tests).

- [ ] **Step 5: Commit**

```bash
git -C C:/mamba_growth add lib/ui/auth/view_models/auth_view_model.dart test/ui/auth/view_models/auth_view_model_test.dart
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

b) Substituir o uso de `_BrandMark(label: l10n.appName)` por `BrandMark(label: l10n.appName)`.

c) Remover toda a classe privada `class _BrandMark extends StatelessWidget { ... }` no fim do arquivo.

- [ ] **Step 3: Validar analyze**

Run: `cd C:/mamba_growth && flutter analyze`
Expected: "No issues found!"

- [ ] **Step 4: Smoke test rápido**

Run: `cd C:/mamba_growth && flutter test test/widget_test.dart`
Expected: Passa (ou ignorável se for o template — mas não pode quebrar build).

- [ ] **Step 5: Commit**

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

## Task 15: `AuthBottomSheet` + widget tests

**Files:**
- Create: `lib/ui/auth/widgets/auth_bottom_sheet.dart`
- Test: `test/ui/auth/widgets/auth_bottom_sheet_test.dart`

> Tarefa maior. Implementação inclui drag handle, título/subtítulo dinâmicos, botão Google, divider OR, dois TextField, erro inline, submit CTA e toggle row. Widget tests cobrem comportamento essencial.

- [ ] **Step 1: Escrever o teste falhando**

Conteúdo de `test/ui/auth/widgets/auth_bottom_sheet_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamba_growth/data/repositories/auth/auth_repository.dart';
import 'package:mamba_growth/domain/models/auth_exception.dart';
import 'package:mamba_growth/domain/models/auth_user.dart';
import 'package:mamba_growth/l10n/generated/app_localizations.dart';
import 'package:mamba_growth/ui/auth/widgets/auth_bottom_sheet.dart';
import 'package:mamba_growth/ui/core/themes/themes.dart';
import 'package:mamba_growth/utils/result.dart';
import 'package:provider/provider.dart';

class _FakeAuthRepository extends ChangeNotifier implements AuthRepository {
  Future<Result<void>> Function()? onSignInEmail;
  Future<Result<void>> Function()? onSignUpEmail;
  Future<Result<void>> Function()? onSignInGoogle;

  @override
  AuthUser? get currentUser => null;

  @override
  bool get isAuthenticated => false;

  @override
  bool get isInitialized => true;

  @override
  Future<Result<void>> signInWithEmail({required String email, required String password}) {
    return (onSignInEmail ?? () async => const Result.ok(null))();
  }

  @override
  Future<Result<void>> signUpWithEmail({required String email, required String password}) {
    return (onSignUpEmail ?? () async => const Result.ok(null))();
  }

  @override
  Future<Result<void>> signInWithGoogle() {
    return (onSignInGoogle ?? () async => const Result.ok(null))();
  }

  @override
  Future<Result<void>> signOut() async => const Result.ok(null);
}

Future<void> _pumpSheet(WidgetTester tester, _FakeAuthRepository repo) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<AuthRepository>.value(
      value: repo,
      child: MaterialApp(
        theme: AppTheme.dark(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => AuthBottomSheet.show(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('starts in sign-in mode with title "Welcome back"', (tester) async {
    final repo = _FakeAuthRepository();
    await _pumpSheet(tester, repo);

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsWidgets); // CTA + maybe toggle
  });

  testWidgets('toggle switches to sign-up mode title', (tester) async {
    final repo = _FakeAuthRepository();
    await _pumpSheet(tester, repo);

    await tester.tap(find.text('Create one'));
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
  });

  testWidgets('shows inline error when invalid credentials returned', (tester) async {
    final repo = _FakeAuthRepository()
      ..onSignInEmail = () async => Result.error(
            const AuthException(AuthErrorKind.invalidCredentials),
          );

    await _pumpSheet(tester, repo);

    await tester.enterText(find.byKey(const Key('auth-email-field')), 'a@b.c');
    await tester.enterText(find.byKey(const Key('auth-password-field')), 'pw');
    await tester.tap(find.byKey(const Key('auth-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Invalid email or password.'), findsOneWidget);
  });

  testWidgets('submit button shows loading and is disabled while running', (tester) async {
    final repo = _FakeAuthRepository()
      ..onSignInEmail = () async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return const Result.ok(null);
      };

    await _pumpSheet(tester, repo);
    await tester.enterText(find.byKey(const Key('auth-email-field')), 'a@b.c');
    await tester.enterText(find.byKey(const Key('auth-password-field')), 'pw');
    await tester.tap(find.byKey(const Key('auth-submit-button')));
    await tester.pump(const Duration(milliseconds: 30));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
  });
}
```

- [ ] **Step 2: Rodar teste — esperar falha**

Run: `cd C:/mamba_growth && flutter test test/ui/auth/widgets/auth_bottom_sheet_test.dart`
Expected: Compile error.

- [ ] **Step 3: Implementar `lib/ui/auth/widgets/auth_bottom_sheet.dart`**

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
    final anyRunning = activeCmd.running || googleCmd.running;

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
              _GoogleButton(
                label: l10n.authContinueWithGoogle,
                running: googleCmd.running,
                disabled: anyRunning,
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
                enabled: !anyRunning,
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
                enabled: !anyRunning,
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
                  onPressed: anyRunning ? null : () => _submit(vm),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: colors.bg,
                    disabledBackgroundColor: colors.accent.withValues(alpha: 0.5),
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
                            valueColor: AlwaysStoppedAnimation(colors.bg),
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
                    onPressed: anyRunning ? null : vm.toggleMode,
                    child: Text(toggleAction),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
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
        Expanded(
          child: Container(height: 1, color: colors.borderDim),
        ),
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
        Expanded(
          child: Container(height: 1, color: colors.borderDim),
        ),
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
        final colors = context.colors;
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

> Nota técnica: `AnimatedBuilder(animation: command)` rebuilda só o `_InlineError` quando o command muda. O `context.watch<AuthViewModel>()` no `_AuthSheetContent` cobre `mode`. O CTA observa `vm` indiretamente via watch + os builds rerodam ao mudar `running`. Para precisão, o CTA mostra spinner com base em `activeCmd.running` que é avaliado a cada build do parent — quando o command notifica, vm não notifica mas como o `_AuthSheetContent` consome o `vm` (e cada command é notifier), fechamos com um `AnimatedBuilder` no scope do parent. Para simplificar, o widget já refaz o rebuild via `context.watch<AuthViewModel>()`. Isso bate, porque os commands disparam notifyListeners mas o parent recebe rebuilds via `vm.notifyListeners` somente em `toggleMode`. **Para garantir rebuild dos botões durante `running`, embrulhe a árvore de botões num `AnimatedBuilder(animation: Listenable.merge([activeCmd, googleCmd]), ...)`** — alteração descrita abaixo.

- [ ] **Step 4: Ajuste de rebuild dos botões**

Refatorar o trecho do `_AuthSheetContent.build` que monta `_GoogleButton` e o submit `FilledButton` envolvendo-os em um `AnimatedBuilder` que escuta os dois commands. Substitua o trecho:

```dart
              _GoogleButton(
                label: l10n.authContinueWithGoogle,
                running: googleCmd.running,
                disabled: anyRunning,
                onPressed: () => _submitGoogle(vm),
              ),
```

por:

```dart
              AnimatedBuilder(
                animation: Listenable.merge([activeCmd, googleCmd]),
                builder: (context, _) {
                  final running = activeCmd.running || googleCmd.running;
                  return _GoogleButton(
                    label: l10n.authContinueWithGoogle,
                    running: googleCmd.running,
                    disabled: running,
                    onPressed: () => _submitGoogle(vm),
                  );
                },
              ),
```

E o submit `FilledButton`: envolver o widget atual num `AnimatedBuilder(animation: Listenable.merge([activeCmd, googleCmd]), builder: (context, _) { final running = ...; return SizedBox(...); })`.

> Os campos de texto (`_LabeledTextField`) também leem `enabled: !anyRunning` — eles ficam dentro do mesmo `AnimatedBuilder` se quiser rebuild deles também. Para simplicidade, podemos envolver toda a `Column` interna num único `AnimatedBuilder` que escuta os dois commands. **Ajuste preferido**: envolver toda a Column de form (Google → submit → toggle) num único `AnimatedBuilder` cuja `animation` é `Listenable.merge([activeCmd, googleCmd])`. O conteúdo continua o mesmo, apenas re-renderiza quando algum command notifica.

Edite o `build` para isso e mantenha a coluna externa igual. Resultado final: as partes que dependem de `running` (Google, fields, submit, toggle, inline error) ficam dentro do AnimatedBuilder; o título/subtítulo/divider ficam fora (dependem só do `vm.mode` via watch).

- [ ] **Step 5: Rodar teste — esperar verde**

Run: `cd C:/mamba_growth && flutter test test/ui/auth/widgets/auth_bottom_sheet_test.dart`
Expected: `All tests passed!` (4 tests).

- [ ] **Step 6: Validar analyze**

Run: `cd C:/mamba_growth && flutter analyze`
Expected: "No issues found!"

- [ ] **Step 7: Commit**

```bash
git -C C:/mamba_growth add lib/ui/auth/widgets/auth_bottom_sheet.dart test/ui/auth/widgets/auth_bottom_sheet_test.dart
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

## Task 17: `buildRouter` + testes de redirect

**Files:**
- Create: `lib/routing/router.dart`
- Test: `test/routing/router_test.dart`

- [ ] **Step 1: Escrever teste falhando**

Conteúdo de `test/routing/router_test.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamba_growth/data/repositories/auth/auth_repository.dart';
import 'package:mamba_growth/domain/models/auth_user.dart';
import 'package:mamba_growth/l10n/generated/app_localizations.dart';
import 'package:mamba_growth/routing/router.dart';
import 'package:mamba_growth/routing/routes.dart';
import 'package:mamba_growth/utils/result.dart';
import 'package:provider/provider.dart';

class _StubAuthRepository extends ChangeNotifier implements AuthRepository {
  _StubAuthRepository({this.initialized = false, this.user});

  bool initialized;
  AuthUser? user;

  void setState({required bool initialized, AuthUser? user}) {
    this.initialized = initialized;
    this.user = user;
    notifyListeners();
  }

  @override
  AuthUser? get currentUser => user;

  @override
  bool get isAuthenticated => user != null;

  @override
  bool get isInitialized => initialized;

  @override
  Future<Result<void>> signInWithEmail({required String email, required String password}) async =>
      const Result.ok(null);

  @override
  Future<Result<void>> signUpWithEmail({required String email, required String password}) async =>
      const Result.ok(null);

  @override
  Future<Result<void>> signInWithGoogle() async => const Result.ok(null);

  @override
  Future<Result<void>> signOut() async => const Result.ok(null);
}

Future<void> _pumpApp(WidgetTester tester, _StubAuthRepository repo) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<AuthRepository>.value(
      value: repo,
      child: MaterialApp.router(
        routerConfig: buildRouter(authRepository: repo),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('not initialized → stays on splash', (tester) async {
    final repo = _StubAuthRepository();
    await _pumpApp(tester, repo);

    expect(find.byKey(const Key('splash-screen')), findsOneWidget);
  });

  testWidgets('initialized + not authenticated → onboarding', (tester) async {
    final repo = _StubAuthRepository(initialized: true);
    await _pumpApp(tester, repo);

    expect(find.byKey(const Key('onboarding-screen')), findsOneWidget);
  });

  testWidgets('initialized + authenticated → home', (tester) async {
    final repo = _StubAuthRepository(
      initialized: true,
      user: const AuthUser(uid: 'u1', email: 'a@b.c'),
    );
    await _pumpApp(tester, repo);

    expect(find.byKey(const Key('home-screen')), findsOneWidget);
  });

  testWidgets('login transition: not authed → authed redirects to home', (tester) async {
    final repo = _StubAuthRepository(initialized: true);
    await _pumpApp(tester, repo);
    expect(find.byKey(const Key('onboarding-screen')), findsOneWidget);

    repo.setState(
      initialized: true,
      user: const AuthUser(uid: 'u1', email: 'a@b.c'),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-screen')), findsOneWidget);
  });
}
```

> **Pré-requisito da implementação**: precisamos adicionar `Key('splash-screen')`, `Key('onboarding-screen')` e `Key('home-screen')` nos respectivos widgets. Step 4 abaixo cobre essa edição.

- [ ] **Step 2: Rodar teste — esperar falha**

Run: `cd C:/mamba_growth && flutter test test/routing/router_test.dart`
Expected: Compile error (`buildRouter` não existe).

- [ ] **Step 3: Implementar `lib/routing/router.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../data/repositories/auth/auth_repository.dart';
import '../l10n/generated/app_localizations.dart';
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
          final l10n = AppLocalizations.of(context);
          return OnboardingScreen(
            key: const Key('onboarding-screen'),
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
        builder: (_, __) =>
            const HomePlaceholderScreen(key: Key('home-screen')),
      ),
    ],
  );
}
```

> Nota: `OnboardingScreen` e `HomePlaceholderScreen` recebem `Key` aqui pra que os widget tests achem-as. `SplashScreen` precisa de `Key('splash-screen')` — adicionado no próximo step.

- [ ] **Step 4: Adicionar keys**

Editar `lib/ui/splash/widgets/splash_screen.dart`: trocar `const SplashScreen({super.key})` para passar a key default `Key('splash-screen')`. Forma mais simples: deixar o construtor como está e o `GoRoute` builder usa `const SplashScreen(key: Key('splash-screen'))`.

Substituir no `router.dart`:

```dart
      GoRoute(
        path: Routes.splash,
        name: RouteNames.splash,
        builder: (_, __) => const SplashScreen(key: Key('splash-screen')),
      ),
```

(Se já adicionou `key: Key('splash-screen')` no router builder no step 3, não precisa mexer no widget.)

Para `OnboardingScreen`, a `Key` no builder do router já cobre. Para `HomePlaceholderScreen`, idem.

- [ ] **Step 5: Rodar teste — esperar verde**

Run: `cd C:/mamba_growth && flutter test test/routing/router_test.dart`
Expected: `All tests passed!` (4 tests).

> Se algum teste falhar por `AppLocalizations.of(context).appName` retornar null em testes, é porque a `MaterialApp.router` precisa dos delegates. O `_pumpApp` já passa os delegates corretos.

- [ ] **Step 6: Commit**

```bash
git -C C:/mamba_growth add lib/routing/router.dart test/routing/router_test.dart
git -C C:/mamba_growth commit -m "feat(routing): add GoRouter with auth-aware redirect"
```

---

## Task 18: Refatorar `main.dart` (bootstrap async + DI raiz)

**Files:**
- Modify: `lib/main.dart`

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

> Nota: removemos o import de `OnboardingScreen` e o uso direto em `home`. O router agora é responsável.

- [ ] **Step 2: Rodar todos os testes**

Run: `cd C:/mamba_growth && flutter test`
Expected: todos os arquivos de teste passam (incluindo `test/widget_test.dart` se ainda existir — pode precisar atualizar conforme step 3).

- [ ] **Step 3: Atualizar `test/widget_test.dart` (template)**

O template atual chama `MyApp()`, que não existe mais. Substituir o conteúdo de `test/widget_test.dart` por um teste mínimo que carrega o app com fakes:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamba_growth/data/repositories/auth/auth_repository.dart';
import 'package:mamba_growth/domain/models/auth_user.dart';
import 'package:mamba_growth/main.dart';
import 'package:mamba_growth/utils/result.dart';

class _NoopAuthRepository extends ChangeNotifier implements AuthRepository {
  @override
  AuthUser? get currentUser => null;

  @override
  bool get isAuthenticated => false;

  @override
  bool get isInitialized => true;

  @override
  Future<Result<void>> signInWithEmail({required String email, required String password}) async =>
      const Result.ok(null);

  @override
  Future<Result<void>> signUpWithEmail({required String email, required String password}) async =>
      const Result.ok(null);

  @override
  Future<Result<void>> signInWithGoogle() async => const Result.ok(null);

  @override
  Future<Result<void>> signOut() async => const Result.ok(null);
}

void main() {
  testWidgets('app boots and renders onboarding when not authenticated', (tester) async {
    await tester.pumpWidget(MambaGrowthApp(authRepository: _NoopAuthRepository()));
    await tester.pumpAndSettle();

    // Onboarding mostra a brand mark com o app name.
    expect(find.text('MAMBA GROWTH'), findsOneWidget);
  });
}
```

- [ ] **Step 4: Rodar todos os testes — esperar verde**

Run: `cd C:/mamba_growth && flutter test`
Expected: `All tests passed!` em todas as suítes.

- [ ] **Step 5: Validar analyze**

Run: `cd C:/mamba_growth && flutter analyze`
Expected: "No issues found!"

- [ ] **Step 6: Commit**

```bash
git -C C:/mamba_growth add lib/main.dart test/widget_test.dart
git -C C:/mamba_growth commit -m "feat(app): wire async bootstrap, DI root and router"
```

---

## Task 19: Configuração nativa Android

**Files:**
- Modify (se necessário): `android/build.gradle` ou `android/build.gradle.kts`
- Modify (se necessário): `android/app/build.gradle` ou `android/app/build.gradle.kts`

- [ ] **Step 1: Inspecionar `android/build.gradle*`**

Run: `cd C:/mamba_growth && ls android/ && cat android/build.gradle 2>/dev/null || cat android/build.gradle.kts 2>/dev/null`
Expected: ver o classpath de plugins.

- [ ] **Step 2: Garantir plugin Google Services no project-level**

Se `android/build.gradle` (Groovy) — bloco `buildscript.dependencies`:

```groovy
classpath 'com.google.gms:google-services:4.4.2'
```

Se `android/build.gradle.kts` (Kotlin) — bloco `plugins` no settings ou `buildscript`:

```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.2")
    }
}
```

Adicionar **só se ausente**.

- [ ] **Step 3: Garantir plugin aplicado no app-level**

Em `android/app/build.gradle` (Groovy), no topo:

```groovy
apply plugin: 'com.google.gms.google-services'
```

Em `android/app/build.gradle.kts`, dentro do bloco `plugins`:

```kotlin
plugins {
    id("com.google.gms.google-services")
}
```

Adicionar **só se ausente**.

- [ ] **Step 4: Verificar minSdk**

`firebase_auth 6.x` exige `minSdkVersion >= 23`. No `android/app/build.gradle*`, garantir:

```
minSdkVersion 23   // ou minSdk = 23 em Kotlin DSL
```

- [ ] **Step 5: Build Android**

Run: `cd C:/mamba_growth && flutter build apk --debug`
Expected: build succeeds. Se faltar plugin, aplicar e re-rodar.

- [ ] **Step 6: Commit (somente se houver mudança)**

```bash
git -C C:/mamba_growth status --short
# Se houver arquivos modificados:
git -C C:/mamba_growth add android/
git -C C:/mamba_growth commit -m "chore(android): apply google-services plugin and minSdk 23"
```

> Se nenhum arquivo precisou ser alterado, pular o commit e seguir.

---

## Task 20: Configuração nativa iOS (manual + verificação)

**Files:**
- Modify (manual): `ios/Runner/Info.plist`

> Esta tarefa pode exigir intervenção manual do usuário se ele não estiver em ambiente macOS. O agente deve documentar e parar para que o usuário aplique se necessário.

- [ ] **Step 1: Verificar presença de `GoogleService-Info.plist`**

Run: `ls C:/mamba_growth/ios/Runner/GoogleService-Info.plist`
Expected: arquivo existe. Se não existir, `flutterfire configure` precisa ser rodado para iOS — o usuário deve fazer isso fora do flow do plano (não há forma confiável do agente executar configuração interativa).

- [ ] **Step 2: Verificar `REVERSED_CLIENT_ID` em `Info.plist`**

Abrir `ios/Runner/Info.plist`. Se não existir bloco `CFBundleURLTypes` registrando o `REVERSED_CLIENT_ID`, adicionar antes do `</dict>` final:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>REPLACE_WITH_REVERSED_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

`REPLACE_WITH_REVERSED_CLIENT_ID` deve vir do campo `REVERSED_CLIENT_ID` dentro de `GoogleService-Info.plist`.

- [ ] **Step 3: Verificar `Podfile`**

Abrir `ios/Podfile`. Garantir:

```ruby
platform :ios, '13.0'
```

- [ ] **Step 4: Documentar passos manuais (se ambiente não-macOS)**

Se rodando em Windows (caso atual), build iOS e teste real precisam ser feitos no macOS. Adicionar ao final de `docs/superpowers/specs/2026-04-28-firebase-auth-design.md` uma seção "iOS verification" listando o que falta — ou criar `docs/superpowers/notes/2026-04-28-ios-followup.md` com o checklist.

Conteúdo de `docs/superpowers/notes/2026-04-28-ios-followup.md`:

```markdown
# iOS follow-up — Firebase Auth

Para validar/testar o build iOS após o merge do auth flow:

1. Abrir `ios/Runner.xcworkspace` no Xcode (Mac).
2. Verificar que `GoogleService-Info.plist` está adicionado ao target Runner.
3. Rodar `pod install` em `ios/`.
4. `flutter run -d ios` e validar:
   - Sign in com email/senha funciona.
   - Sign in com Google funciona (tela do Google aparece).
   - Sign out volta para onboarding.
5. Se Google não funcionar, conferir `CFBundleURLSchemes` no `Info.plist`.
```

- [ ] **Step 5: Commit (mudanças em iOS ou doc)**

```bash
git -C C:/mamba_growth add ios/Runner/Info.plist docs/superpowers/notes/2026-04-28-ios-followup.md
git -C C:/mamba_growth commit -m "chore(ios): document Firebase Auth follow-up and URL scheme"
```

> Se não houve nenhuma alteração local (ex: não há acesso ao plist e o doc nem foi necessário), pular essa task.

---

## Task 21: Console Firebase (manual — não-código)

**Files:** nenhum.

> Esta task é uma checagem manual via Firebase Console. Sem código, sem commit. O agente apenas registra que foi feito.

- [ ] **Step 1: Habilitar provider Email/Password**

Acessar https://console.firebase.google.com → projeto `mamba-growth-kn` → Authentication → Sign-in method → Email/Password → **Enable** → Save.

- [ ] **Step 2: Habilitar provider Google**

Mesma tela → Google → Enable → preencher e-mail de suporte do projeto → Save.

- [ ] **Step 3: Confirmar conclusão**

Não tem commit. Apenas confirmar com o usuário/owner que essas duas opções estão habilitadas antes de testar manualmente.

---

## Task 22: Smoke test end-to-end (manual)

**Files:** nenhum.

> Validar acceptance criteria do spec §11. Nenhum código novo.

- [ ] **Step 1: Executar app em dispositivo Android**

Run: `cd C:/mamba_growth && flutter run -d <android-device-id>`

- [ ] **Step 2: Validar checklist do spec**

Marcar manualmente cada item de §11 do spec:

- [ ] `flutter analyze` passa.
- [ ] `flutter test` passa.
- [ ] App instala e roda no Android.
- [ ] Sign in com email/senha funciona contra usuário criado no console.
- [ ] Sign up cria usuário; após criação, vai para `/home`.
- [ ] Sign in com Google funciona (Android com Play Services).
- [ ] Sign out na home volta para `/onboarding`.
- [ ] Reabrir app com sessão ativa → vai direto para `/home` (sem onboarding).
- [ ] Erro de credencial inválida aparece inline no sheet.
- [ ] Cancelar Google Sign-In não mostra erro.
- [ ] Cores/typo/spacing 100% via design system.

- [ ] **Step 3: Marcar plano como completo**

Não tem commit; apenas comunicação ao usuário e atualização de eventual status.

---

## Self-review

### Spec coverage
- §1 Goal → cumprido por Tasks 11–22.
- §2 Non-goals → respeitados (forgot/verify/freezed/use cases ausentes).
- §3 Architecture → Tasks 2–11.
- §4 File layout → Tasks 1–18 (todos os arquivos criados).
- §5 Detailed design → Tasks 2–18 cobrem cada subseção.
- §6 Dependencies → Task 1.
- §7 Native config → Tasks 19–20.
- §8 Localization → Task 6.
- §9 Testing strategy → Tasks 2, 3, 5, 10, 11, 15, 17 (4 suítes principais + utils).
- §10 Risks → mitigations distribuídas (`supportsAuthenticate` no Google button na Task 15; splash on initial location na Task 17; viewInsets na Task 15).
- §11 Acceptance criteria → Task 22.
- §12 Out of scope → respeitado.

### Placeholder scan
Sem TBD/TODO funcionais no plano — apenas um `REPLACE_WITH_REVERSED_CLIENT_ID` legítimo (placeholder de configuração XML que vai ser preenchido pelo valor real do plist).

### Type consistency
- `Result<T>`, `Ok<T>`, `Error<T>` consistentes entre Tasks 2, 3, 10, 11, 15, 17, 18.
- `AuthErrorKind` cases enumerados em Task 5 e referenciados exatamente em Task 15 (switch exaustivo).
- `Command0`/`Command1` API (`execute`, `running`, `result`, `error`, `completed`, `clearResult`) idêntica entre Tasks 3, 11, 15.
- `AuthRepository` interface (`currentUser`, `isAuthenticated`, `isInitialized`, 4 métodos `Future<Result<void>>`) idêntica nos fakes das Tasks 11, 15, 17, 18.
- `EmailPasswordInput({email, password})` consistente entre Tasks 11 e 15.
- Keys de widgets (`auth-email-field`, `auth-password-field`, `auth-submit-button`, `splash-screen`, `onboarding-screen`, `home-screen`) batem entre tests (15, 17) e widgets (15, 17).
