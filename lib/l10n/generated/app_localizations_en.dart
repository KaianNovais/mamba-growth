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
  String get onboardingTitle => 'Eat with intention.\nFast with clarity.';

  @override
  String get onboardingSubtitle =>
      'Track every fast and every calorie in one calm space. No noise, no shame — just honest numbers that show your real progress.';

  @override
  String get onboardingHeroLabel => 'FASTING';

  @override
  String get onboardingHeroFootnote => 'Sample day · 10h 24m of 16h';

  @override
  String get onboardingPillarFocus => 'Awareness';

  @override
  String get onboardingPillarDiscipline => 'Consistency';

  @override
  String get onboardingPillarGrowth => 'Insight';

  @override
  String get onboardingPrimaryCta => 'Start';

  @override
  String get onboardingFooter =>
      'By continuing you agree with our Terms and Privacy Policy.';

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
  String get authErrorInvalidCredentials => 'Invalid email or password.';

  @override
  String get authErrorEmailInUse => 'An account already exists for this email.';

  @override
  String get authErrorWeakPassword => 'Password must be at least 6 characters.';

  @override
  String get authErrorUserDisabled => 'This account has been disabled.';

  @override
  String get authErrorNetwork => 'No internet connection.';

  @override
  String get authErrorTooManyRequests => 'Too many attempts. Try again later.';

  @override
  String get authErrorGoogleSignInFailed => 'Could not sign in with Google.';

  @override
  String get authErrorUnknown => 'Something went wrong. Please try again.';

  @override
  String homeWelcomeGreeting(String name) {
    return 'Welcome, $name';
  }

  @override
  String get homeComingSoon => 'Your home is coming soon.';

  @override
  String get homeSignOut => 'Sign out';
}
