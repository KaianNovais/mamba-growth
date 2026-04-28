// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'Mamba Growth';

  @override
  String get onboardingEyebrow => 'JEJUM & CALORIAS';

  @override
  String get onboardingTitle => 'Coma com propósito.\nJejue com clareza.';

  @override
  String get onboardingSubtitle =>
      'Acompanhe cada jejum e cada caloria em um só lugar. Sem ruído, sem culpa — só números honestos que mostram seu progresso real.';

  @override
  String get onboardingHeroLabel => 'EM JEJUM';

  @override
  String get onboardingHeroFootnote => 'Dia exemplo · 10h 24m de 16h';

  @override
  String get onboardingPillarFocus => 'Consciência';

  @override
  String get onboardingPillarDiscipline => 'Consistência';

  @override
  String get onboardingPillarGrowth => 'Visão';

  @override
  String get onboardingPrimaryCta => 'Começar';

  @override
  String get onboardingFooter =>
      'Ao continuar você concorda com nossos Termos e Política de Privacidade.';

  @override
  String get onboardingFooterTermsLabel => 'Termos';

  @override
  String get onboardingFooterPrivacyLabel => 'Política de Privacidade';

  @override
  String get authSignInTitle => 'Bem-vindo de volta';

  @override
  String get authSignUpTitle => 'Crie sua conta';

  @override
  String get authSignInSubtitle => 'Entre para continuar sua jornada.';

  @override
  String get authSignUpSubtitle => 'Comece a acompanhar com intenção.';

  @override
  String get authEmailLabel => 'E-mail';

  @override
  String get authEmailHint => 'voce@email.com';

  @override
  String get authPasswordLabel => 'Senha';

  @override
  String get authPasswordVisibilityShow => 'Mostrar senha';

  @override
  String get authPasswordVisibilityHide => 'Ocultar senha';

  @override
  String get authSubmitSignIn => 'Entrar';

  @override
  String get authSubmitSignUp => 'Criar conta';

  @override
  String get authContinueWithGoogle => 'Continuar com Google';

  @override
  String get authDividerOr => 'OU';

  @override
  String get authToggleToSignUpPrompt => 'Não tem uma conta?';

  @override
  String get authToggleToSignUpAction => 'Criar agora';

  @override
  String get authToggleToSignInPrompt => 'Já tem uma conta?';

  @override
  String get authToggleToSignInAction => 'Entrar';

  @override
  String get authErrorInvalidCredentials => 'E-mail ou senha incorretos.';

  @override
  String get authErrorEmailInUse => 'Já existe uma conta com esse e-mail.';

  @override
  String get authErrorWeakPassword =>
      'A senha precisa ter no mínimo 6 caracteres.';

  @override
  String get authErrorUserDisabled => 'Esta conta foi desativada.';

  @override
  String get authErrorNetwork => 'Sem conexão com a internet.';

  @override
  String get authErrorTooManyRequests =>
      'Muitas tentativas. Tente novamente em instantes.';

  @override
  String get authErrorGoogleSignInFailed =>
      'Não foi possível entrar com Google.';

  @override
  String get authErrorUnknown => 'Algo deu errado. Tente novamente.';

  @override
  String homeWelcomeGreeting(String name) {
    return 'Olá, $name';
  }

  @override
  String get homeComingSoon => 'Sua tela inicial está chegando.';

  @override
  String get homeSignOut => 'Sair';
}
