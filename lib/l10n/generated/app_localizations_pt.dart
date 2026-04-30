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
  String get navFasting => 'Jejum';

  @override
  String get navMeals => 'Refeições';

  @override
  String get navHistory => 'Histórico';

  @override
  String get navProfile => 'Perfil';

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
  String get homeEndDialogTitle => 'Não desista agora';

  @override
  String homeEndDialogBody(String elapsed, String target) {
    return 'Você jejuou $elapsed de $target. Sua progressão será salva no histórico.';
  }

  @override
  String homeEndDialogProgress(int percent, String remaining) {
    return '$percent% completo · faltam $remaining';
  }

  @override
  String get homeEndDialogStayCta => 'Continuar jejuando';

  @override
  String get homeEndDialogQuitCta => 'Encerrar mesmo assim';

  @override
  String get homeEndDialogCancel => 'Cancelar';

  @override
  String get homeEndDialogConfirm => 'Encerrar';

  @override
  String get homeFastCompletedTitle => 'Jejum concluído!';

  @override
  String homeFastCompletedBody(String duration) {
    return 'Você jejuou $duration. Salvo no seu histórico.';
  }

  @override
  String get homeFastCompletedDismiss => 'Continuar';

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
  String get homeNewEmptyTitle => 'Em breve.';

  @override
  String get homeNewEmptySubtitle => 'Seu resumo do dia vai morar aqui.';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get profileHistorySectionEyebrow => 'ATIVIDADE';

  @override
  String get profileHistoryRowTitle => 'Histórico de jejuns';

  @override
  String get profileHistoryRowSubtitle => 'Veja seus jejuns concluídos';

  @override
  String get profileMealsHistoryRowTitle => 'Histórico de calorias';

  @override
  String get profileMealsHistoryRowSubtitle => 'Revise seus dias anteriores';

  @override
  String get mealsHistoryTitle => 'Histórico de calorias';

  @override
  String get mealsHistoryEmptyTitle => 'Nada por aqui ainda.';

  @override
  String get mealsHistoryEmptySubtitle =>
      'Suas refeições registradas vão aparecer aqui conforme você acumula histórico.';

  @override
  String get mealsHistoryMealsCountOne => '1 refeição';

  @override
  String mealsHistoryMealsCountMany(int count) {
    return '$count refeições';
  }

  @override
  String get mealsHistoryDayEmpty => 'Nenhuma refeição neste dia.';

  @override
  String get historyDayEmpty => 'Nenhum jejum neste dia.';

  @override
  String weekSelectorDayA11y(String weekday, int day, String state) {
    String _temp0 = intl.Intl.selectLogic(state, {
      'today': ', hoje',
      'selected': ', selecionado',
      'future': ', dia futuro, indisponível',
      'other': '',
    });
    return '$weekday, dia $day$_temp0';
  }

  @override
  String get profileEmptyTitle => 'Em breve.';

  @override
  String get profileEmptySubtitle =>
      'Configurações da conta e personalizações vão morar aqui.';

  @override
  String get profileSignOut => 'Sair';

  @override
  String mealsTodayEyebrowWithGoal(int goal) {
    return 'HOJE · META $goal KCAL';
  }

  @override
  String get mealsTodayEyebrowNoGoal => 'HOJE';

  @override
  String get mealsKcalUnit => 'kcal';

  @override
  String mealsRemainingLabel(int n) {
    return '$n kcal restantes';
  }

  @override
  String mealsOfGoalLabel(int goal) {
    return 'de $goal kcal';
  }

  @override
  String mealsOverGoalLabel(int n) {
    return '$n kcal acima da meta';
  }

  @override
  String get mealsAtGoalLabel => 'Meta atingida';

  @override
  String get mealsListEyebrowOne => 'HOJE · 1 REFEIÇÃO';

  @override
  String mealsListEyebrowMany(int count) {
    return 'HOJE · $count REFEIÇÕES';
  }

  @override
  String get mealsAddCta => 'Adicionar refeição';

  @override
  String get mealsEmptyTodayTitle => 'Nenhuma refeição registrada hoje.';

  @override
  String get mealsEmptyTodaySubtitle =>
      'Toque no botão abaixo para registrar sua primeira refeição do dia.';

  @override
  String get mealsNoGoalHint =>
      'Defina uma meta no perfil para acompanhar seu progresso';

  @override
  String get mealSheetNewTitle => 'Nova refeição';

  @override
  String get mealSheetEditTitle => 'Editar refeição';

  @override
  String mealSheetTimeLabel(String time) {
    return 'Hoje · $time';
  }

  @override
  String get mealSheetNameLabel => 'Nome';

  @override
  String get mealSheetNameHint => 'Café da manhã';

  @override
  String get mealSheetCaloriesLabel => 'Calorias';

  @override
  String get mealSheetSave => 'Salvar';

  @override
  String get mealSheetSaveEdit => 'Salvar alterações';

  @override
  String get mealSheetCancel => 'Cancelar';

  @override
  String get mealItemMenuEdit => 'Editar';

  @override
  String get mealItemMenuDelete => 'Excluir';

  @override
  String get mealDeleteDialogTitle => 'Excluir refeição?';

  @override
  String get mealDeleteDialogBody => 'Você pode desfazer logo após excluir.';

  @override
  String get mealDeleteDialogConfirm => 'Excluir';

  @override
  String get mealDeleteDialogCancel => 'Cancelar';

  @override
  String get mealDeletedSnackbar => 'Refeição removida';

  @override
  String get mealDeletedSnackbarUndo => 'Desfazer';

  @override
  String get mealAddedSnackbar => 'Refeição adicionada';

  @override
  String get mealUpdatedSnackbar => 'Refeição atualizada';

  @override
  String get mealsErrorGeneric => 'Não consegui salvar. Tente novamente.';

  @override
  String get mealValidationNameRequired => 'Informe o nome';

  @override
  String get mealValidationNameTooLong => 'Máximo 60 caracteres';

  @override
  String get mealValidationCaloriesRequired => 'Informe as calorias';

  @override
  String get mealValidationCaloriesRange => 'Entre 1 e 9999';

  @override
  String mealItemA11y(String name, int calories, String time) {
    return '$name, $calories kcal, registrado às $time. Toque para editar.';
  }

  @override
  String mealsRingA11yWithGoal(int consumed, int goal, int remaining) {
    return '$consumed kcal de $goal. $remaining restantes.';
  }

  @override
  String mealsRingA11yOverGoal(int consumed, int over, int goal) {
    return '$consumed kcal. $over acima da meta de $goal.';
  }

  @override
  String mealsRingA11yNoGoal(int consumed) {
    return '$consumed kcal hoje.';
  }

  @override
  String get profileGoalSectionEyebrow => 'CALORIAS';

  @override
  String get profileGoalCardTitle => 'Meta diária';

  @override
  String profileGoalCardValue(int kcal) {
    return '$kcal kcal por dia';
  }

  @override
  String get profileGoalCardEmptyValue => 'Acompanhe seu progresso diário';

  @override
  String get profileGoalCardActionDefine => 'Definir';

  @override
  String get profileGoalCardActionEdit => 'Editar';

  @override
  String get profileGoalSheetTitle => 'Meta diária';

  @override
  String get profileGoalSheetSubtitle =>
      'Quantas calorias você quer consumir por dia?';

  @override
  String get profileGoalSheetSuggestionsLabel => 'Sugestões';

  @override
  String get profileGoalSheetSave => 'Salvar';

  @override
  String get profileGoalSheetRemove => 'Remover meta';

  @override
  String get profileGoalValidationRange => 'Entre 500 e 9999';
}
