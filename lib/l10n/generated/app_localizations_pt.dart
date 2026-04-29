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
  String get navHome => 'Início';

  @override
  String get navMeals => 'Refeições';

  @override
  String get navHistory => 'Histórico';

  @override
  String get navStats => 'Stats';

  @override
  String get homeFastingTitle => 'Jejum';

  @override
  String get homeProfileAction => 'Perfil';

  @override
  String get homeProtocolAction => 'Trocar protocolo';

  @override
  String get homeStartFast => 'Iniciar jejum';

  @override
  String get homeEndFast => 'Encerrar jejum';

  @override
  String get homeElapsedLabel => 'decorrido';

  @override
  String get homeFastingTargetLabel => 'meta de jejum';

  @override
  String get homeProtocolEyebrow => 'Protocolo';

  @override
  String get homeNextProtocolEyebrow => 'Próximo protocolo';

  @override
  String homeEndsIn(String duration) {
    return 'Termina em $duration';
  }

  @override
  String homeEndsAt(String time) {
    return 'às $time';
  }

  @override
  String get homeGoalReached => 'Meta atingida';

  @override
  String homeGoalReachedAgo(String duration) {
    return 'há $duration';
  }

  @override
  String homeEatingWindow(int hours) {
    return 'Janela alimentar de ${hours}h';
  }

  @override
  String get homeEndDialogTitle => 'Encerrar jejum?';

  @override
  String homeEndDialogBody(String elapsed, String target) {
    return 'Você jejuou $elapsed de $target. Sua progressão será salva no histórico.';
  }

  @override
  String homeEndDialogSurpassed(String over) {
    return 'Você superou sua meta em $over · ótimo trabalho.';
  }

  @override
  String get homeEndDialogCancel => 'Cancelar';

  @override
  String get homeEndDialogConfirm => 'Encerrar';

  @override
  String get homeProtocolSheetTitle => 'Protocolo de jejum';

  @override
  String get homeProtocolSheetSubtitle =>
      'Escolha quanto tempo você vai jejuar.';

  @override
  String get homeProtocolBeginner => 'iniciante';

  @override
  String get homeProtocolPopular => 'popular';

  @override
  String get homeProtocolAdvanced => 'avançado';

  @override
  String get homeProtocolCustom => 'Personalizado';

  @override
  String homeProtocolCustomLabel(int fast, int eat) {
    return '${fast}h jejum · ${eat}h alimentação';
  }

  @override
  String get homeProtocolConfirm => 'Selecionar protocolo';

  @override
  String get homeNotificationFastEndTitle => 'Jejum concluído';

  @override
  String get homeNotificationFastEndBody =>
      'Você atingiu sua meta. Quebre o jejum quando estiver pronto.';

  @override
  String homeRingSemanticsActive(
    int elapsedH,
    int elapsedM,
    int remainingH,
    int remainingM,
    int target,
  ) {
    return 'Jejum $elapsedH horas e $elapsedM minutos. Faltam $remainingH horas e $remainingM minutos para a meta de $target horas.';
  }

  @override
  String homeRingSemanticsIdle(int target) {
    return 'Pronto para iniciar jejum de $target horas.';
  }

  @override
  String get mealsEmptyTitle => 'Nenhuma refeição registrada.';

  @override
  String get mealsEmptySubtitle =>
      'Adicione sua primeira refeição para começar a ver suas calorias do dia com intenção.';

  @override
  String get historyEmptyTitle => 'Nada no seu histórico.';

  @override
  String get historyEmptySubtitle =>
      'Jejuns passados e dias registrados aparecem aqui conforme você constrói consistência.';

  @override
  String historyItemSummary(String elapsed, String target) {
    return '$elapsed de $target';
  }

  @override
  String get historyItemStatusCompleted => 'Concluído';

  @override
  String get historyItemStatusEarly => 'Encerrado antes';

  @override
  String get historyItemTestProtocol => 'Teste · 2 min';

  @override
  String get historyDateToday => 'Hoje';

  @override
  String get historyDateYesterday => 'Ontem';

  @override
  String get statsEmptyTitle => 'Insights a caminho.';

  @override
  String get statsEmptySubtitle =>
      'Com alguns dias registrados, você vê tendências honestas e seu progresso real aqui.';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get profileEmptyTitle => 'Em breve.';

  @override
  String get profileEmptySubtitle =>
      'Configurações da conta e personalizações vão morar aqui.';

  @override
  String get profileSignOut => 'Sair';
}
