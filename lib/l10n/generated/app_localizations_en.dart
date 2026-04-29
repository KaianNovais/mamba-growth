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
  String get navMeals => 'Meals';

  @override
  String get navHistory => 'History';

  @override
  String get navStats => 'Stats';

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
  String get homeEndDialogTitle => 'End fast?';

  @override
  String homeEndDialogBody(String elapsed, String target) {
    return 'You fasted $elapsed of $target. Your progress will be saved to history.';
  }

  @override
  String homeEndDialogSurpassed(String over) {
    return 'You beat your goal by $over · great work.';
  }

  @override
  String get homeEndDialogCancel => 'Cancel';

  @override
  String get homeEndDialogConfirm => 'End';

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
  String get statsEmptyTitle => 'Insights on the way.';

  @override
  String get statsEmptySubtitle =>
      'Once you log a few days, you\'ll see honest trends and real progress here.';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileEmptyTitle => 'Coming soon.';

  @override
  String get profileEmptySubtitle =>
      'Account settings and customizations will live here.';

  @override
  String get profileSignOut => 'Sign out';
}
