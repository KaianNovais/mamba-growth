// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Mamba Growth';

  @override
  String get onboardingEyebrow => 'FASTING & CALORIES';

  @override
  String get onboardingTitle => 'Eat with purpose.\nFast with clarity.';

  @override
  String get onboardingSubtitle =>
      'Track every fast and every calorie in one place. No noise, no shame — just honest numbers showing your real progress.';

  @override
  String get onboardingHeroLabel => 'FASTING';

  @override
  String get onboardingHeroFootnote => 'Sample day · 10h 24m of 16h';

  @override
  String get onboardingPillarFocus => 'Awareness';

  @override
  String get onboardingPillarDiscipline => 'Consistency';

  @override
  String get onboardingPillarGrowth => 'Vision';

  @override
  String get onboardingPrimaryCta => 'Get started';

  @override
  String get onboardingFooter =>
      'By continuing you agree to our Terms and Privacy Policy.';

  @override
  String get onboardingFooterTermsLabel => 'Terms';

  @override
  String get onboardingFooterPrivacyLabel => 'Privacy Policy';

  @override
  String get authSignInTitle => 'Welcome back';

  @override
  String get authSignUpTitle => 'Create your account';

  @override
  String get authSignInSubtitle => 'Sign in to continue your journey.';

  @override
  String get authSignUpSubtitle => 'Start tracking with intention.';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailHint => 'you@email.com';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordVisibilityShow => 'Show password';

  @override
  String get authPasswordVisibilityHide => 'Hide password';

  @override
  String get authSubmitSignIn => 'Sign in';

  @override
  String get authSubmitSignUp => 'Create account';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authDividerOr => 'OR';

  @override
  String get authToggleToSignUpPrompt => 'Don\'t have an account?';

  @override
  String get authToggleToSignUpAction => 'Create one';

  @override
  String get authToggleToSignInPrompt => 'Already have an account?';

  @override
  String get authToggleToSignInAction => 'Sign in';

  @override
  String get authErrorInvalidCredentials => 'Wrong email or password.';

  @override
  String get authErrorEmailInUse => 'An account already exists for this email.';

  @override
  String get authErrorWeakPassword => 'Password must be at least 6 characters.';

  @override
  String get authErrorUserDisabled => 'This account has been disabled.';

  @override
  String get authErrorNetwork => 'No internet connection.';

  @override
  String get authErrorTooManyRequests =>
      'Too many attempts. Try again in a moment.';

  @override
  String get authErrorGoogleSignInFailed => 'Couldn\'t sign in with Google.';

  @override
  String get authErrorUnknown => 'Something went wrong. Try again.';

  @override
  String get navHome => 'Home';

  @override
  String get navFasting => 'Fasting';

  @override
  String get navMeals => 'Meals';

  @override
  String get navHistory => 'History';

  @override
  String get navProfile => 'Profile';

  @override
  String get homeFastingTitle => 'Fasting';

  @override
  String get homeProfileAction => 'Profile';

  @override
  String get homeProtocolAction => 'Change protocol';

  @override
  String get homeStartFast => 'Start fast';

  @override
  String get homeEndFast => 'End fast';

  @override
  String get homeElapsedLabel => 'elapsed';

  @override
  String get homeFastingTargetLabel => 'fasting target';

  @override
  String get homeProtocolEyebrow => 'Protocol';

  @override
  String get homeNextProtocolEyebrow => 'Next protocol';

  @override
  String homeEndsIn(String duration) {
    return 'Ends in $duration';
  }

  @override
  String homeEndsAt(String time) {
    return 'at $time';
  }

  @override
  String get homeGoalReached => 'Goal reached';

  @override
  String homeGoalReachedAgo(String duration) {
    return '$duration ago';
  }

  @override
  String homeEatingWindow(int hours) {
    return '${hours}h eating window';
  }

  @override
  String get homeEndDialogTitle => 'Don\'t give up now';

  @override
  String homeEndDialogBody(String elapsed, String target) {
    return 'You fasted $elapsed of $target. Your progress will be saved to history.';
  }

  @override
  String homeEndDialogProgress(int percent, String remaining) {
    return '$percent% complete · $remaining to go';
  }

  @override
  String get homeEndDialogStayCta => 'Keep fasting';

  @override
  String get homeEndDialogQuitCta => 'End anyway';

  @override
  String get homeEndDialogCancel => 'Cancel';

  @override
  String get homeEndDialogConfirm => 'End';

  @override
  String get homeFastCompletedTitle => 'Fast complete!';

  @override
  String homeFastCompletedBody(String duration) {
    return 'You fasted $duration. Saved to your history.';
  }

  @override
  String get homeFastCompletedDismiss => 'Continue';

  @override
  String get homeProtocolSheetTitle => 'Fasting protocol';

  @override
  String get homeProtocolSheetSubtitle => 'Choose how long you\'ll fast.';

  @override
  String get homeProtocolBeginner => 'beginner';

  @override
  String get homeProtocolPopular => 'popular';

  @override
  String get homeProtocolAdvanced => 'advanced';

  @override
  String get homeProtocolCustom => 'Custom';

  @override
  String homeProtocolCustomLabel(int fast, int eat) {
    return '${fast}h fasting · ${eat}h eating';
  }

  @override
  String get homeProtocolConfirm => 'Select protocol';

  @override
  String get homeNotificationFastEndTitle => 'Fast complete';

  @override
  String get homeNotificationFastEndBody =>
      'You hit your goal. Break your fast when you\'re ready.';

  @override
  String homeRingSemanticsActive(
    int elapsedH,
    int elapsedM,
    int remainingH,
    int remainingM,
    int target,
  ) {
    return 'Fasting $elapsedH hours and $elapsedM minutes. $remainingH hours and $remainingM minutes left to reach the $target hour goal.';
  }

  @override
  String homeRingSemanticsIdle(int target) {
    return 'Ready to start a $target hour fast.';
  }

  @override
  String get mealsEmptyTitle => 'No meals logged.';

  @override
  String get mealsEmptySubtitle =>
      'Add your first meal to start seeing your calories with intention.';

  @override
  String get historyEmptyTitle => 'Nothing in your history.';

  @override
  String get historyEmptySubtitle =>
      'Past fasts and logged days will appear here as you build consistency.';

  @override
  String historyItemSummary(String elapsed, String target) {
    return '$elapsed of $target';
  }

  @override
  String get historyItemStatusCompleted => 'Completed';

  @override
  String get historyItemStatusEarly => 'Ended early';

  @override
  String get historyItemTestProtocol => 'Test · 2 min';

  @override
  String get historyDateToday => 'Today';

  @override
  String get historyDateYesterday => 'Yesterday';

  @override
  String get homeNewEmptyTitle => 'Coming soon.';

  @override
  String get homeNewEmptySubtitle => 'Your daily snapshot will live here.';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileHistorySectionEyebrow => 'ACTIVITY';

  @override
  String get profileHistoryRowTitle => 'Fasting history';

  @override
  String get profileHistoryRowSubtitle => 'View your past fasts';

  @override
  String get profileMealsHistoryRowTitle => 'Calorie history';

  @override
  String get profileMealsHistoryRowSubtitle => 'Review your past days';

  @override
  String get mealsHistoryTitle => 'Calorie history';

  @override
  String get mealsHistoryEmptyTitle => 'Nothing here yet.';

  @override
  String get mealsHistoryEmptySubtitle =>
      'Your logged meals will appear here as you build a track record.';

  @override
  String get mealsHistoryMealsCountOne => '1 meal';

  @override
  String mealsHistoryMealsCountMany(int count) {
    return '$count meals';
  }

  @override
  String get mealsHistoryDayEmpty => 'No meals logged this day.';

  @override
  String mealsHistoryWeekSelectorA11y(String weekday, int day, String state) {
    String _temp0 = intl.Intl.selectLogic(state, {
      'today': ', today',
      'selected': ', selected',
      'future': ', future, not available',
      'other': '',
    });
    return '$weekday, day $day$_temp0';
  }

  @override
  String get profileEmptyTitle => 'Coming soon.';

  @override
  String get profileEmptySubtitle =>
      'Account settings and customizations will live here.';

  @override
  String get profileSignOut => 'Sign out';

  @override
  String mealsTodayEyebrowWithGoal(int goal) {
    return 'TODAY · GOAL $goal KCAL';
  }

  @override
  String get mealsTodayEyebrowNoGoal => 'TODAY';

  @override
  String get mealsKcalUnit => 'kcal';

  @override
  String mealsRemainingLabel(int n) {
    return '$n kcal remaining';
  }

  @override
  String mealsOfGoalLabel(int goal) {
    return 'of $goal kcal';
  }

  @override
  String mealsOverGoalLabel(int n) {
    return '$n kcal over goal';
  }

  @override
  String get mealsAtGoalLabel => 'Goal reached';

  @override
  String get mealsListEyebrowOne => 'TODAY · 1 MEAL';

  @override
  String mealsListEyebrowMany(int count) {
    return 'TODAY · $count MEALS';
  }

  @override
  String get mealsAddCta => 'Add meal';

  @override
  String get mealsEmptyTodayTitle => 'No meals logged today.';

  @override
  String get mealsEmptyTodaySubtitle =>
      'Tap the button below to log your first meal of the day.';

  @override
  String get mealsNoGoalHint => 'Set a goal in your profile to track progress';

  @override
  String get mealSheetNewTitle => 'New meal';

  @override
  String get mealSheetEditTitle => 'Edit meal';

  @override
  String mealSheetTimeLabel(String time) {
    return 'Today · $time';
  }

  @override
  String get mealSheetNameLabel => 'Name';

  @override
  String get mealSheetNameHint => 'Breakfast';

  @override
  String get mealSheetCaloriesLabel => 'Calories';

  @override
  String get mealSheetSave => 'Save';

  @override
  String get mealSheetSaveEdit => 'Save changes';

  @override
  String get mealSheetCancel => 'Cancel';

  @override
  String get mealItemMenuEdit => 'Edit';

  @override
  String get mealItemMenuDelete => 'Delete';

  @override
  String get mealDeleteDialogTitle => 'Delete meal?';

  @override
  String get mealDeleteDialogBody => 'You can undo right after deleting.';

  @override
  String get mealDeleteDialogConfirm => 'Delete';

  @override
  String get mealDeleteDialogCancel => 'Cancel';

  @override
  String get mealDeletedSnackbar => 'Meal removed';

  @override
  String get mealDeletedSnackbarUndo => 'Undo';

  @override
  String get mealAddedSnackbar => 'Meal added';

  @override
  String get mealUpdatedSnackbar => 'Meal updated';

  @override
  String get mealsErrorGeneric => 'Something went wrong. Try again.';

  @override
  String get mealValidationNameRequired => 'Enter a name';

  @override
  String get mealValidationNameTooLong => 'Max 60 characters';

  @override
  String get mealValidationCaloriesRequired => 'Enter calories';

  @override
  String get mealValidationCaloriesRange => 'Between 1 and 9999';

  @override
  String mealItemA11y(String name, int calories, String time) {
    return '$name, $calories kcal, logged at $time. Tap to edit.';
  }

  @override
  String mealsRingA11yWithGoal(int consumed, int goal, int remaining) {
    return '$consumed kcal of $goal. $remaining remaining.';
  }

  @override
  String mealsRingA11yOverGoal(int consumed, int over, int goal) {
    return '$consumed kcal. $over over goal of $goal.';
  }

  @override
  String mealsRingA11yNoGoal(int consumed) {
    return '$consumed kcal today.';
  }

  @override
  String get profileGoalSectionEyebrow => 'CALORIES';

  @override
  String get profileGoalCardTitle => 'Daily goal';

  @override
  String profileGoalCardValue(int kcal) {
    return '$kcal kcal per day';
  }

  @override
  String get profileGoalCardEmptyValue => 'Track your daily progress';

  @override
  String get profileGoalCardActionDefine => 'Set';

  @override
  String get profileGoalCardActionEdit => 'Edit';

  @override
  String get profileGoalSheetTitle => 'Daily goal';

  @override
  String get profileGoalSheetSubtitle =>
      'How many calories do you want to consume per day?';

  @override
  String get profileGoalSheetSuggestionsLabel => 'Suggestions';

  @override
  String get profileGoalSheetSave => 'Save';

  @override
  String get profileGoalSheetRemove => 'Remove goal';

  @override
  String get profileGoalValidationRange => 'Between 500 and 9999';
}
