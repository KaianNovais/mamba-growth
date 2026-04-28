import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  /// Application brand name.
  ///
  /// In en, this message translates to:
  /// **'Mamba Growth'**
  String get appName;

  /// Eyebrow that anchors the user in what the app is about.
  ///
  /// In en, this message translates to:
  /// **'FASTING & CALORIES'**
  String get onboardingEyebrow;

  /// Hero headline. Two short, parallel sentences.
  ///
  /// In en, this message translates to:
  /// **'Eat with intention.\nFast with clarity.'**
  String get onboardingTitle;

  /// Supporting paragraph below the headline.
  ///
  /// In en, this message translates to:
  /// **'Track every fast and every calorie in one calm space. No noise, no shame — just honest numbers that show your real progress.'**
  String get onboardingSubtitle;

  /// Caption above the live clock value in the hero visual.
  ///
  /// In en, this message translates to:
  /// **'FASTING'**
  String get onboardingHeroLabel;

  /// Tiny footnote below the hero making clear the data is illustrative.
  ///
  /// In en, this message translates to:
  /// **'Sample day · 10h 24m of 16h'**
  String get onboardingHeroFootnote;

  /// Outcome pillar 1 — what the user gains.
  ///
  /// In en, this message translates to:
  /// **'Awareness'**
  String get onboardingPillarFocus;

  /// Outcome pillar 2.
  ///
  /// In en, this message translates to:
  /// **'Consistency'**
  String get onboardingPillarDiscipline;

  /// Outcome pillar 3.
  ///
  /// In en, this message translates to:
  /// **'Insight'**
  String get onboardingPillarGrowth;

  /// Primary CTA. Single-word action verb.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get onboardingPrimaryCta;

  /// Legal footer under the CTAs.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree with our Terms and Privacy Policy.'**
  String get onboardingFooter;

  /// Substring of onboardingFooter to render as an emphasized link (Terms of Service).
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get onboardingFooterTermsLabel;

  /// Substring of onboardingFooter to render as an emphasized link (Privacy Policy).
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get onboardingFooterPrivacyLabel;

  /// Auth bottom sheet title in sign-in mode.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authSignInTitle;

  /// Auth bottom sheet title in sign-up mode.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get authSignUpTitle;

  /// Auth bottom sheet subtitle in sign-in mode.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue your journey.'**
  String get authSignInSubtitle;

  /// Auth bottom sheet subtitle in sign-up mode.
  ///
  /// In en, this message translates to:
  /// **'Start tracking with intention.'**
  String get authSignUpSubtitle;

  /// Email field label.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// Email field hint.
  ///
  /// In en, this message translates to:
  /// **'you@email.com'**
  String get authEmailHint;

  /// Password field label.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// Semantic label to show the password.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authPasswordVisibilityShow;

  /// Semantic label to hide the password.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authPasswordVisibilityHide;

  /// Submit button in sign-in mode.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSubmitSignIn;

  /// Submit button in sign-up mode.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authSubmitSignUp;

  /// Google sign-in button label.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueWithGoogle;

  /// Separator between Google and email/password.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get authDividerOr;

  /// Prompt to switch to sign-up mode.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get authToggleToSignUpPrompt;

  /// Action label to switch to sign-up.
  ///
  /// In en, this message translates to:
  /// **'Create one'**
  String get authToggleToSignUpAction;

  /// Prompt to switch to sign-in mode.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authToggleToSignInPrompt;

  /// Action label to switch to sign-in.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authToggleToSignInAction;

  /// Inline error for invalid credentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get authErrorInvalidCredentials;

  /// Inline error when email is already used.
  ///
  /// In en, this message translates to:
  /// **'An account already exists for this email.'**
  String get authErrorEmailInUse;

  /// Inline error for weak password.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get authErrorWeakPassword;

  /// Inline error when user is disabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled.'**
  String get authErrorUserDisabled;

  /// Inline error for network failure.
  ///
  /// In en, this message translates to:
  /// **'No internet connection.'**
  String get authErrorNetwork;

  /// Inline error for rate limiting.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again later.'**
  String get authErrorTooManyRequests;

  /// Inline error when Google sign-in fails.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in with Google.'**
  String get authErrorGoogleSignInFailed;

  /// Generic fallback inline error.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authErrorUnknown;

  /// Greeting on the home placeholder. {name} is the display name or email.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String homeWelcomeGreeting(String name);

  /// Subtitle on the home placeholder.
  ///
  /// In en, this message translates to:
  /// **'Your home is coming soon.'**
  String get homeComingSoon;

  /// Sign out button label.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get homeSignOut;

  /// Bottom navigation label for the home tab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom navigation label for the meals tab.
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get navMeals;

  /// Bottom navigation label for the history tab.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// Bottom navigation label for the stats tab.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get navStats;

  /// Title shown on the empty home tab.
  ///
  /// In en, this message translates to:
  /// **'Your day starts here.'**
  String get homeEmptyTitle;

  /// Subtitle shown on the empty home tab.
  ///
  /// In en, this message translates to:
  /// **'Once you log a fast or a meal, this is where today\'s signals will live.'**
  String get homeEmptySubtitle;

  /// Title shown on the empty meals tab.
  ///
  /// In en, this message translates to:
  /// **'No meals logged yet.'**
  String get mealsEmptyTitle;

  /// Subtitle shown on the empty meals tab.
  ///
  /// In en, this message translates to:
  /// **'Add your first meal to start seeing your daily calories with intention.'**
  String get mealsEmptySubtitle;

  /// Title shown on the empty history tab.
  ///
  /// In en, this message translates to:
  /// **'Nothing in your history.'**
  String get historyEmptyTitle;

  /// Subtitle shown on the empty history tab.
  ///
  /// In en, this message translates to:
  /// **'Past fasts and logged days will appear here as you build consistency.'**
  String get historyEmptySubtitle;

  /// Title shown on the empty stats tab.
  ///
  /// In en, this message translates to:
  /// **'Insights are on the way.'**
  String get statsEmptyTitle;

  /// Subtitle shown on the empty stats tab.
  ///
  /// In en, this message translates to:
  /// **'Once you have a few days logged, you\'ll see honest trends and progress here.'**
  String get statsEmptySubtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
