# Firebase Auth — Design Spec

**Date:** 2026-04-28
**Status:** Approved (brainstorming) — pending implementation plan
**Owner:** kaiannovais

---

## 1. Goal

Adicionar autenticação ao Mamba Growth — email/senha e Google — disparada por um bottom sheet quando o usuário toca no CTA "Start" do onboarding. A sessão persiste entre aberturas; uma vez logado, o app pula o onboarding e abre direto na home placeholder.

## 2. Non-goals

Para deixar o MVP enxuto, **estão fora deste spec**:

- Forgot password / password reset.
- Email verification gating.
- Provedores extras (Apple, Facebook, anônimo).
- Domain layer / use cases — view model fala direto com o repository.
- `freezed`, code-gen, JSON serialization.
- Cache local persistido — `firebase_auth` já persiste sessão por padrão.
- Retry automático em falhas de rede.
- Suporte completo a web (Google Sign-In em web fica como TODO documentado; botão desabilitado).
- Home real — entra apenas uma `HomePlaceholderScreen` com greeting + sign out.

## 3. Architecture

Padrão MVVM + Repository + Service da skill `flutter-expert` (case study Compass do time Flutter), com `ChangeNotifier` + `provider` como camada de estado. Source of truth é o design system em `lib/ui/core/themes/` — todo widget consome via `context.colors` / `context.text` / `context.typo`.

### 3.1 Layer responsibilities

| Layer | Componente | Responsabilidade |
|---|---|---|
| UI | `AuthBottomSheet` (View) | Renderiza form, observa `AuthViewModel`, dispara comandos. Não conhece Firebase. |
| UI | `AuthViewModel` (`ChangeNotifier`) | Mantém `AuthMode`, expõe `Command0/Command1` para sign in/up/Google. |
| Domain | `AuthUser` (model) | Imutável. Tradução do `User` do Firebase para o app. |
| Domain | `AuthException` / `AuthCancelledException` | Tipos de erro do app, com `kind` que a UI mapeia para l10n. |
| Data | `AuthRepository` (abstract `ChangeNotifier`) | SSOT do `currentUser`. `notifyListeners()` quando sessão muda. |
| Data | `AuthRepositoryFirebase` | Combina os dois services + emite estado. Borda onde exceptions viram `Result`. |
| Data | `FirebaseAuthService` | Wrap fino sobre `FirebaseAuth.instance`. |
| Data | `GoogleSignInService` | Wrap fino sobre `GoogleSignIn.instance` (7.x). Inicializa singleton e devolve `idToken`. |
| Routing | `buildRouter()` | `GoRouter` com `refreshListenable: authRepository` + `redirect` baseado em `isInitialized` e `isAuthenticated`. |

### 3.2 Diagrama

```
┌─────────────────────────────────────────────────────────────┐
│                          UI LAYER                           │
│   OnboardingScreen ──tap CTA──▶ AuthBottomSheet            │
│                                       │                    │
│                                       ▼                    │
│                                AuthViewModel               │
│                          (Command0/Command1, AuthMode)     │
└───────────────────────────────────────┬────────────────────┘
                                        │ chama métodos
                                        ▼
┌─────────────────────────────────────────────────────────────┐
│                         DATA LAYER                          │
│              AuthRepository (ChangeNotifier)                │
│                        │           │                       │
│                        ▼           ▼                       │
│        FirebaseAuthService    GoogleSignInService          │
│        (FirebaseAuth.instance) (GoogleSignIn.instance 7.x) │
└─────────────────────────────────────────────────────────────┘
                        │
                        ▼ refreshListenable
                  GoRouter redirect
```

### 3.3 Unidirectional data flow

1. Tap em "Start" no `OnboardingScreen` → `AuthBottomSheet.show(context)`.
2. Sheet cria `ChangeNotifierProvider<AuthViewModel>` local, lendo `AuthRepository` do context root.
3. Tap no submit → `vm.signInWithEmail.execute(input)` (ou `signUpWithEmail` ou `signInWithGoogle`).
4. Command vira `running = true`, notifica.
5. Repository chama o service correspondente; em sucesso, `FirebaseAuth.authStateChanges` emite o novo `User`.
6. Listener interno do repo atualiza `_currentUser` e chama `notifyListeners()`.
7. `GoRouter.refreshListenable` reage → `redirect` reavalia → vai pra `Routes.home`.
8. Sheet observa o command, vê `completed`, chama `Navigator.pop(context)`.

## 4. File layout

```
lib/
├── data/
│   ├── repositories/auth/
│   │   ├── auth_repository.dart
│   │   └── auth_repository_firebase.dart
│   └── services/auth/
│       ├── firebase_auth_service.dart
│       └── google_sign_in_service.dart
├── domain/
│   └── models/
│       ├── auth_user.dart
│       └── auth_exception.dart
├── routing/
│   ├── routes.dart
│   └── router.dart
├── ui/
│   ├── auth/
│   │   ├── view_models/auth_view_model.dart
│   │   └── widgets/
│   │       ├── auth_bottom_sheet.dart
│   │       └── auth_form_fields.dart
│   ├── core/themes/                       (existente — não alterado)
│   ├── home/
│   │   └── widgets/home_placeholder_screen.dart
│   ├── onboarding/widgets/
│   │   └── onboarding_screen.dart         (sem alteração interna)
│   └── splash/
│       └── widgets/splash_screen.dart
├── utils/
│   ├── command.dart
│   └── result.dart
├── firebase_options.dart                  (existente)
└── main.dart                              (refatorado: bootstrap async + DI raiz)

test/
├── data/repositories/auth/auth_repository_firebase_test.dart
├── ui/auth/view_models/auth_view_model_test.dart
├── ui/auth/widgets/auth_bottom_sheet_test.dart
└── routing/router_test.dart

l10n/
├── app_en.arb                             (+ strings novas)
└── app_pt.arb                             (+ strings novas)

pubspec.yaml                               (+ google_sign_in, go_router, provider, mocktail)
```

## 5. Detailed design

### 5.1 `Result<T>` (`lib/utils/result.dart`)

Sealed class com factories `Result.ok(value)` / `Result.error(exception)`. View models pattern-match sobre `Ok<T>` / `Error<T>`. Nada de exceptions atravessando a borda repo→viewmodel.

### 5.2 `Command0` / `Command1` (`lib/utils/command.dart`)

`Command<T>` extends `ChangeNotifier`. Estado: `running`, `result`, getters `error`/`completed`, método `clearResult()`. Re-entrancy guard: `if (_running) return;`. Notifica listeners no início e no fim. `Command0` para ações sem argumento, `Command1<T, A>` para ações com um argumento.

### 5.3 `AuthUser` (`lib/domain/models/auth_user.dart`)

`@immutable class AuthUser` com `uid`, `email`, `displayName?`, `photoUrl?`. Sem `freezed`, sem JSON.

### 5.4 `AuthException` (`lib/domain/models/auth_exception.dart`)

```dart
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
class AuthException implements Exception {
  const AuthException(this.kind, [this.cause]);
  final AuthErrorKind kind;
  final Object? cause;

  factory AuthException.fromFirebase(FirebaseAuthException e);
  factory AuthException.googleSignInFailed(Object cause);
  factory AuthException.unknown(Object cause);
}
class AuthCancelledException implements Exception {
  const AuthCancelledException();
}
```

Mapeamento Firebase code → kind:

| `FirebaseAuthException.code` | `AuthErrorKind` |
|---|---|
| `invalid-credential`, `invalid-email`, `wrong-password`, `user-not-found` | `invalidCredentials` |
| `email-already-in-use` | `emailAlreadyInUse` |
| `weak-password` | `weakPassword` |
| `user-disabled` | `userDisabled` |
| `network-request-failed` | `networkError` |
| `too-many-requests` | `tooManyRequests` |
| qualquer outro | `unknown` |

`AuthCancelledException` é separada e a view ignora silenciosamente (não mostra erro, só reabilita botão).

### 5.5 `FirebaseAuthService` (`lib/data/services/auth/firebase_auth_service.dart`)

Casca fina sobre `FirebaseAuth.instance`. Sem estado próprio. Métodos:

- `User? get currentUser`
- `Stream<User?> authStateChanges()`
- `Future<UserCredential> signInWithEmailAndPassword({email, password})`
- `Future<UserCredential> createUserWithEmailAndPassword({email, password})`
- `Future<UserCredential> signInWithCredential(AuthCredential credential)`
- `Future<void> signOut()`

Construtor aceita `FirebaseAuth?` opcional para injetar fake em testes.

### 5.6 `GoogleSignInService` (`lib/data/services/auth/google_sign_in_service.dart`)

Wrap sobre `GoogleSignIn.instance` (singleton 7.x). Responsabilidades:

- Inicialização preguiçosa (`_ensureInitialized()`) com `serverClientId` opcional.
- `Future<String> authenticateAndGetIdToken()` — chama `authenticate()`, lê `account.authentication.idToken`. Se idToken vier `null`, lança exceção interna que vira `AuthErrorKind.googleSignInFailed`.
- `Future<void> signOut()`.
- `bool get supportsAuthenticate` — falso em web; usado pela UI para desabilitar/ocultar botão Google em plataformas não suportadas.

`serverClientId` no MVP fica `null` em Android (parseado automaticamente do `google-services.json` pelo plugin nativo). Para iOS/macOS o plugin lê do `Info.plist` via `REVERSED_CLIENT_ID`.

### 5.7 `AuthRepository` (abstract — `lib/data/repositories/auth/auth_repository.dart`)

```dart
abstract class AuthRepository extends ChangeNotifier {
  AuthUser? get currentUser;
  bool get isAuthenticated;
  bool get isInitialized;

  Future<Result<void>> signInWithEmail({required String email, required String password});
  Future<Result<void>> signUpWithEmail({required String email, required String password});
  Future<Result<void>> signInWithGoogle();
  Future<Result<void>> signOut();
}
```

### 5.8 `AuthRepositoryFirebase` (`lib/data/repositories/auth/auth_repository_firebase.dart`)

- Construtor recebe `FirebaseAuthService` e `GoogleSignInService`. Subscribe imediato em `authStateChanges()`.
- Listener: ao receber primeiro evento, marca `isInitialized = true`. Atualiza `_currentUser` e notifica.
- Métodos de auth: try/catch em `FirebaseAuthException` → `AuthException.fromFirebase(...)` → `Result.error(...)`. `Exception` genérica vira `AuthException.unknown`. Em sucesso, retorna `Result.ok(null)`; o `currentUser` se atualiza pelo listener (não pelo retorno).
- `signInWithGoogle`: chama `authenticateAndGetIdToken()`, monta `GoogleAuthProvider.credential(idToken: ...)`, chama `firebase.signInWithCredential(...)`. Cancelamento (`GoogleSignInExceptionCode.canceled`) vira `AuthCancelledException`.
- `signOut`: chama `_google.signOut()` antes de `_firebase.signOut()` para limpar cache do Google.
- `dispose`: cancela subscription.

### 5.9 `AuthViewModel` (`lib/ui/auth/view_models/auth_view_model.dart`)

```dart
enum AuthMode { signIn, signUp }

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({required AuthRepository authRepository});

  AuthMode get mode;
  late final Command1<void, EmailPasswordInput> signInWithEmail;
  late final Command1<void, EmailPasswordInput> signUpWithEmail;
  late final Command0<void> signInWithGoogle;

  void toggleMode();   // alterna mode + limpa results dos commands
}

@immutable class EmailPasswordInput {
  const EmailPasswordInput({required this.email, required this.password});
  final String email;
  final String password;
}
```

View consome `mode` via `context.watch<AuthViewModel>()`, e cada command via `AnimatedBuilder(animation: cmd, ...)` para rebuild surgical.

### 5.10 `AuthBottomSheet` (`lib/ui/auth/widgets/auth_bottom_sheet.dart`)

Método estático: `static Future<void> show(BuildContext context)` envolve `showModalBottomSheet` com:

- `isScrollControlled: true`
- `useSafeArea: true`
- `enableDrag: true`
- `showDragHandle: false` (drag handle custom abaixo)
- `backgroundColor: null` (vem do `bottomSheetTheme.modalBackgroundColor`)
- `shape: null` (vem do tema — `RoundedRectangleBorder(top: AppRadius.rXl)`)
- `builder` cria `ChangeNotifierProvider<AuthViewModel>` local que constrói o VM com `authRepository: context.read<AuthRepository>()`.

Estrutura visual (top → bottom):

1. **Drag handle** custom: `Container(width: 36, height: 4, color: colors.border, borderRadius: full)` com `Padding(top: AppSpacing.sm)`.
2. **Title** — `text.headlineSmall` em `colors.text`. "Welcome back" / "Create your account".
3. **Subtitle** — `text.bodyMedium` em `colors.textDim`. "Sign in to continue" / "Start your journey".
4. **Google button** — `OutlinedButton` (não accent), altura 56, ícone "G" monocromático em `colors.text`. Desabilitado se `!supportsAuthenticate` (e tooltip "Coming soon" via Tooltip).
5. **Divider "OR"** — duas linhas de `colors.borderDim` 1px com `Text("OR", typo.caption, textDimmer, letterSpacing 2.4)` no meio.
6. **Email field** — `Text("Email", typo.caption, textDim)` + `TextField` (theme já configurado), `keyboardType: emailAddress`, `autofillHints: [email]`, `textInputAction: next`.
7. **Password field** — `Text("Password", typo.caption, textDim)` + `TextField` `obscureText: true`, com suffix `IconButton(visibility/visibility_off)`, `autofillHints: [password]` (ou `[newPassword]` em sign up), `textInputAction: done`, `onSubmitted: _submit`.
8. **Erro inline** — `AnimatedSize` + `AnimatedOpacity`. `Row` com `Icon(error_outline, 16, error)` + `Text(message, bodySmall, error)`.
9. **Submit CTA** — `FilledButton` 56h `accent`, `RoundedRectangleBorder(AppRadius.lg)`. Texto "Sign in" / "Create account". Mostra `CircularProgressIndicator` 18×18 em `colors.bg` quando `running`. Desabilitado durante qualquer `running`.
10. **Toggle row** — `Text("Don't have an account?")` + `TextButton("Create one")` inline. Inverte em sign-up.

Padding bottom dinâmico: `EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl)` para não esconder atrás do teclado.

Animação de transição entre modos: `AnimatedSwitcher(duration: 220ms, switchInCurve: easeOutCubic, switchOutCurve: easeInCubic)` envolvendo título/subtítulo/CTA/footer.

Validação no submit:
- Email: regex `^[^@\s]+@[^@\s]+\.[^@\s]+$`. Erro inline → kind sintético `invalidCredentials` (mensagem traduzida).
- Senha: `length >= 6` no sign up; em sign in só checa `isNotEmpty` e deixa Firebase responder.

Em `command.completed` → `Navigator.of(context).pop()`. Em `command.error` cuja causa é `AuthCancelledException` → não mostra erro, apenas zera o command.

### 5.11 `AuthFormFields` (`lib/ui/auth/widgets/auth_form_fields.dart`)

Componentes privados extraídos do sheet quando ficar grande: `_LabeledTextField`, `_PasswordField`, `_GoogleButton`, `_OrDivider`, `_InlineError`, `_DragHandle`. Mantidos no mesmo arquivo se o sheet ficar < 400 linhas; quebrados se passar.

### 5.12 `SplashScreen` (`lib/ui/splash/widgets/splash_screen.dart`)

Tela simples: `Scaffold(backgroundColor: colors.bg)` com Column central — brand mark do onboarding (extraído pra `lib/ui/core/widgets/brand_mark.dart`) + `CircularProgressIndicator` em `colors.accent`. Sem animações pesadas.

> **Refactor pequeno necessário:** `_BrandMark` hoje vive privado em `onboarding_screen.dart`. Vamos extrair para `lib/ui/core/widgets/brand_mark.dart` (público) para que onboarding e splash o reusem. Mudança mínima: cortar/colar a classe e ajustar imports.

### 5.13 `HomePlaceholderScreen` (`lib/ui/home/widgets/home_placeholder_screen.dart`)

Tela placeholder até a home real existir:
- `AppBar` simples (sem leading) com title da brand.
- Body central:
  - `Text(l10n.homeWelcomeGreeting(displayName ?? email), text.headlineSmall)`
  - `Text(l10n.homeComingSoon, bodyMedium, textDim)`
  - `OutlinedButton.icon(icon: logout, label: l10n.homeSignOut, onPressed: () => repo.signOut())`
- Lê `AuthRepository` via `context.watch` para reagir a mudança de user (caso volte para null, router redireciona).

### 5.14 Routing (`lib/routing/`)

```dart
// routes.dart
abstract class Routes {
  static const splash    = '/splash';
  static const onboarding = '/onboarding';
  static const home      = '/home';
}
abstract class RouteNames {
  static const splash    = 'splash';
  static const onboarding = 'onboarding';
  static const home      = 'home';
}

// router.dart
GoRouter buildRouter({required AuthRepository authRepository});
```

`redirect` matrix:

| `isInitialized` | `isAuthenticated` | `loc` | resultado |
|---|---|---|---|
| `false` | — | `splash` | `null` (fica) |
| `false` | — | qualquer outro | `splash` |
| `true` | `true` | `splash` ou `onboarding` | `home` |
| `true` | `true` | `home` | `null` |
| `true` | `false` | `splash` ou `home` | `onboarding` |
| `true` | `false` | `onboarding` | `null` |

### 5.15 `main.dart` refatorado

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firebaseAuthService = FirebaseAuthService();
  final googleSignInService = GoogleSignInService(serverClientId: null);
  final authRepository = AuthRepositoryFirebase(
    firebaseAuthService: firebaseAuthService,
    googleSignInService: googleSignInService,
  );

  runApp(MambaGrowthApp(authRepository: authRepository));
}

class MambaGrowthApp extends StatelessWidget {
  const MambaGrowthApp({super.key, required this.authRepository});
  final AuthRepository authRepository;

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
}
```

### 5.16 Integração com onboarding existente

`OnboardingScreen` **não muda** internamente. Apenas o callback `onContinue`, montado dentro de uma rota wrapper:

```dart
// dentro do GoRoute /onboarding
builder: (context, state) => OnboardingScreen(
  onContinue: () async {
    HapticFeedback.mediumImpact();
    await AuthBottomSheet.show(context);
  },
);
```

## 6. Dependencies

Adicionar em `pubspec.yaml`:

```yaml
dependencies:
  google_sign_in: ^7.2.0
  go_router: ^16.3.0
  provider: ^6.1.5

dev_dependencies:
  mocktail: ^1.0.4
```

`firebase_core ^4.7.0` e `firebase_auth ^6.4.0` já estão presentes.

## 7. Native configuration

### 7.1 Android

- `android/app/google-services.json` ✅ existente.
- Verificar `android/build.gradle` (project): `classpath 'com.google.gms:google-services:4.4.x'`.
- Verificar `android/app/build.gradle`: `apply plugin: 'com.google.gms.google-services'`.
- `minSdkVersion >= 23` (já em `21` no launcher icons; vamos elevar se Firebase exigir).
- Sem ação extra para Google Sign-In: o plugin nativo lê o client ID do `google-services.json`.

### 7.2 iOS

- `ios/Runner/GoogleService-Info.plist` precisa existir e estar adicionado ao target Runner (verificar Xcode project).
- `ios/Runner/Info.plist`: registrar o `REVERSED_CLIENT_ID` como URL scheme:
  ```xml
  <key>CFBundleURLTypes</key>
  <array>
    <dict>
      <key>CFBundleURLSchemes</key>
      <array>
        <string>$(REVERSED_CLIENT_ID)</string>
      </array>
    </dict>
  </array>
  ```
  (substituir pela string concreta se variável não estiver disponível no plist do projeto).
- `Podfile`: garantir `platform :ios, '13.0'` ou superior (firebase_auth 6.x exige).

### 7.3 Console Firebase

Manual, fora do código:
- Habilitar provider **Email/Password**.
- Habilitar provider **Google** (selecionar conta de suporte).

## 8. Localization

Strings novas (chaves em `app_en.arb` e `app_pt.arb`):

| Key | en | pt |
|---|---|---|
| `authSignInTitle` | Welcome back | Bem-vindo de volta |
| `authSignUpTitle` | Create your account | Crie sua conta |
| `authSignInSubtitle` | Sign in to continue your journey. | Entre para continuar sua jornada. |
| `authSignUpSubtitle` | Start tracking with intention. | Comece a acompanhar com intenção. |
| `authEmailLabel` | Email | E-mail |
| `authEmailHint` | you@email.com | voce@email.com |
| `authPasswordLabel` | Password | Senha |
| `authPasswordVisibilityShow` | Show password | Mostrar senha |
| `authPasswordVisibilityHide` | Hide password | Ocultar senha |
| `authSubmitSignIn` | Sign in | Entrar |
| `authSubmitSignUp` | Create account | Criar conta |
| `authContinueWithGoogle` | Continue with Google | Continuar com Google |
| `authDividerOr` | OR | OU |
| `authToggleToSignUpPrompt` | Don't have an account? | Não tem uma conta? |
| `authToggleToSignUpAction` | Create one | Criar agora |
| `authToggleToSignInPrompt` | Already have an account? | Já tem uma conta? |
| `authToggleToSignInAction` | Sign in | Entrar |
| `authErrorInvalidCredentials` | Invalid email or password. | E-mail ou senha incorretos. |
| `authErrorEmailInUse` | An account already exists for this email. | Já existe uma conta com esse e-mail. |
| `authErrorWeakPassword` | Password must be at least 6 characters. | A senha precisa ter no mínimo 6 caracteres. |
| `authErrorUserDisabled` | This account has been disabled. | Esta conta foi desativada. |
| `authErrorNetwork` | No internet connection. | Sem conexão com a internet. |
| `authErrorTooManyRequests` | Too many attempts. Try again later. | Muitas tentativas. Tente novamente em instantes. |
| `authErrorGoogleSignInFailed` | Could not sign in with Google. | Não foi possível entrar com Google. |
| `authErrorUnknown` | Something went wrong. Please try again. | Algo deu errado. Tente novamente. |
| `homeWelcomeGreeting` | Welcome, {name} | Olá, {name} |
| `homeComingSoon` | Your home is coming soon. | Sua tela inicial está chegando. |
| `homeSignOut` | Sign out | Sair |

`homeWelcomeGreeting` é uma string com placeholder `{name}` (ICU plural-ready se um dia precisar).

## 9. Testing strategy

Mínimo testável agora:

### 9.1 `auth_repository_firebase_test.dart`
- Sucesso `signInWithEmail` → service chamado, `Result.ok` retornado.
- `FirebaseAuthException(invalid-credential)` → `Result.error(AuthException(invalidCredentials))`.
- `email-already-in-use` em `signUpWithEmail` → kind correto.
- `signInWithGoogle` sucesso → `authenticateAndGetIdToken` + `signInWithCredential` chamados na ordem.
- Cancelamento Google (`GoogleSignInExceptionCode.canceled`) → `Result.error(AuthCancelledException)`.
- `authStateChanges` emite `User` → `currentUser` atualiza + `notifyListeners` disparado.
- `signOut` → ambos services chamados.

### 9.2 `auth_view_model_test.dart`
- `signInWithEmail.execute(input)` → command transita running→completed.
- `toggleMode()` → `mode` alterna E `clearResult()` chamado nos commands.
- Re-execução durante `running` é ignorada.

### 9.3 `auth_bottom_sheet_test.dart` (widget)
- Modo signIn → mostra título "Welcome back".
- Modo signUp (após toggle) → mostra título "Create your account".
- Erro inline visível quando `command.error == true`.
- Submit desabilitado quando `command.running == true`.

### 9.4 `router_test.dart`
- Não inicializado → fica em `splash`.
- Inicializado + não autenticado → vai pra `onboarding`.
- Inicializado + autenticado → vai pra `home`.

Fakes via `mocktail`. Sem testes E2E com Firebase real.

## 10. Risks & mitigations

| Risco | Mitigação |
|---|---|
| `serverClientId` ausente em iOS | Plugin lê do `Info.plist` — instrumentação via teste manual de build iOS antes de mergir. |
| Google Sign-In em web | `supportsAuthenticate` falso → botão desabilitado com tooltip "Coming soon". TODO documentado em `auth_bottom_sheet.dart`. |
| Splash flicker em sessão fria | `redirect` segura no `splash` enquanto `!isInitialized`; primeira frame não pode mostrar `onboarding`. Teste de router cobre. |
| Sheet com teclado aberto fica cortado | `MediaQuery.viewInsetsOf(context).bottom` no padding + `isScrollControlled: true`. Verificar em device real (iPhone SE, Android telas pequenas). |
| `firebase_options.dart` desatualizado | Não regerar no MVP. Documentar `flutterfire configure` como processo manual quando adicionar plataformas. |

## 11. Acceptance criteria

- [ ] `flutter analyze` passa.
- [ ] `flutter test` passa (4 suites listadas em §9).
- [ ] Build Android instala e roda.
- [ ] Sign in com email/senha funciona contra um usuário criado no console.
- [ ] Sign up cria usuário no console; após criação, `currentUser` está populado e usuário vai pra `/home`.
- [ ] Sign in com Google funciona em Android (device físico ou emulador com Google Play Services).
- [ ] Sign out na home volta para `/onboarding`.
- [ ] Reabrir o app com sessão ativa não mostra onboarding — vai direto pra `/home`.
- [ ] Erro de credencial inválida aparece inline no sheet.
- [ ] Cancelamento de Google Sign-In não mostra mensagem de erro, só reabilita o botão.
- [ ] Todas as cores/tipografia/spacing do sheet vêm via `context.colors`/`context.text`/`AppSpacing` — zero hardcode.

## 12. Out of scope (lembrete)

Fora deste spec — virão em specs futuras:
- Forgot password.
- Email verification.
- Apple Sign-In, anonymous, link/unlink providers.
- Home real (substituir `HomePlaceholderScreen`).
- Suporte completo a web.
- Persistência local de domínio (fasting sessions, calorias).
