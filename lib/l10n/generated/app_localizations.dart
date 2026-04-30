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

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Mamba Growth'**
  String get appName;

  /// No description provided for @onboardingEyebrow.
  ///
  /// In en, this message translates to:
  /// **'FASTING & CALORIES'**
  String get onboardingEyebrow;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Eat with purpose.\nFast with clarity.'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track every fast and every calorie in one place. No noise, no shame — just honest numbers showing your real progress.'**
  String get onboardingSubtitle;

  /// No description provided for @onboardingHeroLabel.
  ///
  /// In en, this message translates to:
  /// **'FASTING'**
  String get onboardingHeroLabel;

  /// No description provided for @onboardingHeroFootnote.
  ///
  /// In en, this message translates to:
  /// **'Sample day · 10h 24m of 16h'**
  String get onboardingHeroFootnote;

  /// No description provided for @onboardingPillarFocus.
  ///
  /// In en, this message translates to:
  /// **'Awareness'**
  String get onboardingPillarFocus;

  /// No description provided for @onboardingPillarDiscipline.
  ///
  /// In en, this message translates to:
  /// **'Consistency'**
  String get onboardingPillarDiscipline;

  /// No description provided for @onboardingPillarGrowth.
  ///
  /// In en, this message translates to:
  /// **'Vision'**
  String get onboardingPillarGrowth;

  /// No description provided for @onboardingPrimaryCta.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingPrimaryCta;

  /// No description provided for @onboardingFooter.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to our Terms and Privacy Policy.'**
  String get onboardingFooter;

  /// No description provided for @onboardingFooterTermsLabel.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get onboardingFooterTermsLabel;

  /// No description provided for @onboardingFooterPrivacyLabel.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get onboardingFooterPrivacyLabel;

  /// No description provided for @authSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authSignInTitle;

  /// No description provided for @authSignUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get authSignUpTitle;

  /// No description provided for @authSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue your journey.'**
  String get authSignInSubtitle;

  /// No description provided for @authSignUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start tracking with intention.'**
  String get authSignUpSubtitle;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authEmailHint.
  ///
  /// In en, this message translates to:
  /// **'you@email.com'**
  String get authEmailHint;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authPasswordVisibilityShow.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authPasswordVisibilityShow;

  /// No description provided for @authPasswordVisibilityHide.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authPasswordVisibilityHide;

  /// No description provided for @authSubmitSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSubmitSignIn;

  /// No description provided for @authSubmitSignUp.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authSubmitSignUp;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authDividerOr.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get authDividerOr;

  /// No description provided for @authToggleToSignUpPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get authToggleToSignUpPrompt;

  /// No description provided for @authToggleToSignUpAction.
  ///
  /// In en, this message translates to:
  /// **'Create one'**
  String get authToggleToSignUpAction;

  /// No description provided for @authToggleToSignInPrompt.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authToggleToSignInPrompt;

  /// No description provided for @authToggleToSignInAction.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authToggleToSignInAction;

  /// No description provided for @authErrorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Wrong email or password.'**
  String get authErrorInvalidCredentials;

  /// No description provided for @authErrorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'An account already exists for this email.'**
  String get authErrorEmailInUse;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled.'**
  String get authErrorUserDisabled;

  /// No description provided for @authErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection.'**
  String get authErrorNetwork;

  /// No description provided for @authErrorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in a moment.'**
  String get authErrorTooManyRequests;

  /// No description provided for @authErrorGoogleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sign in with Google.'**
  String get authErrorGoogleSignInFailed;

  /// No description provided for @authErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get authErrorUnknown;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navFasting.
  ///
  /// In en, this message translates to:
  /// **'Fasting'**
  String get navFasting;

  /// No description provided for @navMeals.
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get navMeals;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @homeFastingTitle.
  ///
  /// In en, this message translates to:
  /// **'Fasting'**
  String get homeFastingTitle;

  /// No description provided for @homeProfileAction.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get homeProfileAction;

  /// No description provided for @homeProtocolAction.
  ///
  /// In en, this message translates to:
  /// **'Change protocol'**
  String get homeProtocolAction;

  /// No description provided for @homeStartFast.
  ///
  /// In en, this message translates to:
  /// **'Start fast'**
  String get homeStartFast;

  /// No description provided for @homeEndFast.
  ///
  /// In en, this message translates to:
  /// **'End fast'**
  String get homeEndFast;

  /// No description provided for @homeElapsedLabel.
  ///
  /// In en, this message translates to:
  /// **'elapsed'**
  String get homeElapsedLabel;

  /// No description provided for @homeFastingTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'fasting target'**
  String get homeFastingTargetLabel;

  /// No description provided for @homeProtocolEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Protocol'**
  String get homeProtocolEyebrow;

  /// No description provided for @homeNextProtocolEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Next protocol'**
  String get homeNextProtocolEyebrow;

  /// No description provided for @homeEndsIn.
  ///
  /// In en, this message translates to:
  /// **'Ends in {duration}'**
  String homeEndsIn(String duration);

  /// No description provided for @homeEndsAt.
  ///
  /// In en, this message translates to:
  /// **'at {time}'**
  String homeEndsAt(String time);

  /// No description provided for @homeGoalReached.
  ///
  /// In en, this message translates to:
  /// **'Goal reached'**
  String get homeGoalReached;

  /// No description provided for @homeGoalReachedAgo.
  ///
  /// In en, this message translates to:
  /// **'{duration} ago'**
  String homeGoalReachedAgo(String duration);

  /// No description provided for @homeEatingWindow.
  ///
  /// In en, this message translates to:
  /// **'{hours}h eating window'**
  String homeEatingWindow(int hours);

  /// No description provided for @homeEndDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Don\'t give up now'**
  String get homeEndDialogTitle;

  /// No description provided for @homeEndDialogBody.
  ///
  /// In en, this message translates to:
  /// **'You fasted {elapsed} of {target}. Your progress will be saved to history.'**
  String homeEndDialogBody(String elapsed, String target);

  /// No description provided for @homeEndDialogProgress.
  ///
  /// In en, this message translates to:
  /// **'{percent}% complete · {remaining} to go'**
  String homeEndDialogProgress(int percent, String remaining);

  /// No description provided for @homeEndDialogStayCta.
  ///
  /// In en, this message translates to:
  /// **'Keep fasting'**
  String get homeEndDialogStayCta;

  /// No description provided for @homeEndDialogQuitCta.
  ///
  /// In en, this message translates to:
  /// **'End anyway'**
  String get homeEndDialogQuitCta;

  /// No description provided for @homeEndDialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get homeEndDialogCancel;

  /// No description provided for @homeEndDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get homeEndDialogConfirm;

  /// No description provided for @homeFastCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Fast complete!'**
  String get homeFastCompletedTitle;

  /// No description provided for @homeFastCompletedBody.
  ///
  /// In en, this message translates to:
  /// **'You fasted {duration}. Saved to your history.'**
  String homeFastCompletedBody(String duration);

  /// No description provided for @homeFastCompletedDismiss.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get homeFastCompletedDismiss;

  /// No description provided for @homeProtocolSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Fasting protocol'**
  String get homeProtocolSheetTitle;

  /// No description provided for @homeProtocolSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how long you\'ll fast.'**
  String get homeProtocolSheetSubtitle;

  /// No description provided for @homeProtocolBeginner.
  ///
  /// In en, this message translates to:
  /// **'beginner'**
  String get homeProtocolBeginner;

  /// No description provided for @homeProtocolPopular.
  ///
  /// In en, this message translates to:
  /// **'popular'**
  String get homeProtocolPopular;

  /// No description provided for @homeProtocolAdvanced.
  ///
  /// In en, this message translates to:
  /// **'advanced'**
  String get homeProtocolAdvanced;

  /// No description provided for @homeProtocolCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get homeProtocolCustom;

  /// No description provided for @homeProtocolCustomLabel.
  ///
  /// In en, this message translates to:
  /// **'{fast}h fasting · {eat}h eating'**
  String homeProtocolCustomLabel(int fast, int eat);

  /// No description provided for @homeProtocolConfirm.
  ///
  /// In en, this message translates to:
  /// **'Select protocol'**
  String get homeProtocolConfirm;

  /// No description provided for @homeNotificationFastEndTitle.
  ///
  /// In en, this message translates to:
  /// **'Fast complete'**
  String get homeNotificationFastEndTitle;

  /// No description provided for @homeNotificationFastEndBody.
  ///
  /// In en, this message translates to:
  /// **'You hit your goal. Break your fast when you\'re ready.'**
  String get homeNotificationFastEndBody;

  /// No description provided for @homeRingSemanticsActive.
  ///
  /// In en, this message translates to:
  /// **'Fasting {elapsedH} hours and {elapsedM} minutes. {remainingH} hours and {remainingM} minutes left to reach the {target} hour goal.'**
  String homeRingSemanticsActive(
    int elapsedH,
    int elapsedM,
    int remainingH,
    int remainingM,
    int target,
  );

  /// No description provided for @homeRingSemanticsIdle.
  ///
  /// In en, this message translates to:
  /// **'Ready to start a {target} hour fast.'**
  String homeRingSemanticsIdle(int target);

  /// No description provided for @mealsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No meals logged.'**
  String get mealsEmptyTitle;

  /// No description provided for @mealsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first meal to start seeing your calories with intention.'**
  String get mealsEmptySubtitle;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing in your history.'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Past fasts and logged days will appear here as you build consistency.'**
  String get historyEmptySubtitle;

  /// No description provided for @historyItemSummary.
  ///
  /// In en, this message translates to:
  /// **'{elapsed} of {target}'**
  String historyItemSummary(String elapsed, String target);

  /// No description provided for @historyItemStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get historyItemStatusCompleted;

  /// No description provided for @historyItemStatusEarly.
  ///
  /// In en, this message translates to:
  /// **'Ended early'**
  String get historyItemStatusEarly;

  /// No description provided for @historyDateToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get historyDateToday;

  /// No description provided for @historyDateYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get historyDateYesterday;

  /// No description provided for @homeNewEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming soon.'**
  String get homeNewEmptyTitle;

  /// No description provided for @homeNewEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your daily snapshot will live here.'**
  String get homeNewEmptySubtitle;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileHistorySectionEyebrow.
  ///
  /// In en, this message translates to:
  /// **'ACTIVITY'**
  String get profileHistorySectionEyebrow;

  /// No description provided for @profileHistoryRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Fasting history'**
  String get profileHistoryRowTitle;

  /// No description provided for @profileHistoryRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View your past fasts'**
  String get profileHistoryRowSubtitle;

  /// No description provided for @profileMealsHistoryRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Calorie history'**
  String get profileMealsHistoryRowTitle;

  /// No description provided for @profileMealsHistoryRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review your past days'**
  String get profileMealsHistoryRowSubtitle;

  /// No description provided for @mealsHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Calorie history'**
  String get mealsHistoryTitle;

  /// No description provided for @mealsHistoryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet.'**
  String get mealsHistoryEmptyTitle;

  /// No description provided for @mealsHistoryEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your logged meals will appear here as you build a track record.'**
  String get mealsHistoryEmptySubtitle;

  /// No description provided for @mealsHistoryMealsCountOne.
  ///
  /// In en, this message translates to:
  /// **'1 meal'**
  String get mealsHistoryMealsCountOne;

  /// No description provided for @mealsHistoryMealsCountMany.
  ///
  /// In en, this message translates to:
  /// **'{count} meals'**
  String mealsHistoryMealsCountMany(int count);

  /// No description provided for @mealsHistoryDayEmpty.
  ///
  /// In en, this message translates to:
  /// **'No meals logged this day.'**
  String get mealsHistoryDayEmpty;

  /// No description provided for @historyDayEmpty.
  ///
  /// In en, this message translates to:
  /// **'No fasts logged this day.'**
  String get historyDayEmpty;

  /// No description provided for @weekSelectorDayA11y.
  ///
  /// In en, this message translates to:
  /// **'{weekday}, day {day}{state, select, today{, today} selected{, selected} future{, future, not available} other{}}'**
  String weekSelectorDayA11y(String weekday, int day, String state);

  /// No description provided for @profileEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming soon.'**
  String get profileEmptyTitle;

  /// No description provided for @profileEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Account settings and customizations will live here.'**
  String get profileEmptySubtitle;

  /// No description provided for @profileSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get profileSignOut;

  /// No description provided for @mealsTodayEyebrowWithGoal.
  ///
  /// In en, this message translates to:
  /// **'TODAY · GOAL {goal} KCAL'**
  String mealsTodayEyebrowWithGoal(int goal);

  /// No description provided for @mealsTodayEyebrowNoGoal.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get mealsTodayEyebrowNoGoal;

  /// No description provided for @mealsKcalUnit.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get mealsKcalUnit;

  /// No description provided for @mealsRemainingLabel.
  ///
  /// In en, this message translates to:
  /// **'{n} kcal remaining'**
  String mealsRemainingLabel(int n);

  /// No description provided for @mealsOfGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'of {goal} kcal'**
  String mealsOfGoalLabel(int goal);

  /// No description provided for @mealsOverGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'{n} kcal over goal'**
  String mealsOverGoalLabel(int n);

  /// No description provided for @mealsAtGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal reached'**
  String get mealsAtGoalLabel;

  /// No description provided for @mealsListEyebrowOne.
  ///
  /// In en, this message translates to:
  /// **'TODAY · 1 MEAL'**
  String get mealsListEyebrowOne;

  /// No description provided for @mealsListEyebrowMany.
  ///
  /// In en, this message translates to:
  /// **'TODAY · {count} MEALS'**
  String mealsListEyebrowMany(int count);

  /// No description provided for @mealsAddCta.
  ///
  /// In en, this message translates to:
  /// **'Add meal'**
  String get mealsAddCta;

  /// No description provided for @mealsEmptyTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'No meals logged today.'**
  String get mealsEmptyTodayTitle;

  /// No description provided for @mealsEmptyTodaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap the button below to log your first meal of the day.'**
  String get mealsEmptyTodaySubtitle;

  /// No description provided for @mealsNoGoalHint.
  ///
  /// In en, this message translates to:
  /// **'Set a goal in your profile to track progress'**
  String get mealsNoGoalHint;

  /// No description provided for @mealSheetNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New meal'**
  String get mealSheetNewTitle;

  /// No description provided for @mealSheetEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit meal'**
  String get mealSheetEditTitle;

  /// No description provided for @mealSheetTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Today · {time}'**
  String mealSheetTimeLabel(String time);

  /// No description provided for @mealSheetNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get mealSheetNameLabel;

  /// No description provided for @mealSheetNameHint.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get mealSheetNameHint;

  /// No description provided for @mealSheetCaloriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get mealSheetCaloriesLabel;

  /// No description provided for @mealSheetSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get mealSheetSave;

  /// No description provided for @mealSheetSaveEdit.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get mealSheetSaveEdit;

  /// No description provided for @mealSheetCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get mealSheetCancel;

  /// No description provided for @mealItemMenuEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get mealItemMenuEdit;

  /// No description provided for @mealItemMenuDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get mealItemMenuDelete;

  /// No description provided for @mealDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete meal?'**
  String get mealDeleteDialogTitle;

  /// No description provided for @mealDeleteDialogBody.
  ///
  /// In en, this message translates to:
  /// **'You can undo right after deleting.'**
  String get mealDeleteDialogBody;

  /// No description provided for @mealDeleteDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get mealDeleteDialogConfirm;

  /// No description provided for @mealDeleteDialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get mealDeleteDialogCancel;

  /// No description provided for @mealDeletedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Meal removed'**
  String get mealDeletedSnackbar;

  /// No description provided for @mealDeletedSnackbarUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get mealDeletedSnackbarUndo;

  /// No description provided for @mealAddedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Meal added'**
  String get mealAddedSnackbar;

  /// No description provided for @mealUpdatedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Meal updated'**
  String get mealUpdatedSnackbar;

  /// No description provided for @mealsErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get mealsErrorGeneric;

  /// No description provided for @mealValidationNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get mealValidationNameRequired;

  /// No description provided for @mealValidationNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Max 60 characters'**
  String get mealValidationNameTooLong;

  /// No description provided for @mealValidationCaloriesRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter calories'**
  String get mealValidationCaloriesRequired;

  /// No description provided for @mealValidationCaloriesRange.
  ///
  /// In en, this message translates to:
  /// **'Between 1 and 9999'**
  String get mealValidationCaloriesRange;

  /// No description provided for @mealItemA11y.
  ///
  /// In en, this message translates to:
  /// **'{name}, {calories} kcal, logged at {time}. Tap to edit.'**
  String mealItemA11y(String name, int calories, String time);

  /// No description provided for @mealsRingA11yWithGoal.
  ///
  /// In en, this message translates to:
  /// **'{consumed} kcal of {goal}. {remaining} remaining.'**
  String mealsRingA11yWithGoal(int consumed, int goal, int remaining);

  /// No description provided for @mealsRingA11yOverGoal.
  ///
  /// In en, this message translates to:
  /// **'{consumed} kcal. {over} over goal of {goal}.'**
  String mealsRingA11yOverGoal(int consumed, int over, int goal);

  /// No description provided for @mealsRingA11yNoGoal.
  ///
  /// In en, this message translates to:
  /// **'{consumed} kcal today.'**
  String mealsRingA11yNoGoal(int consumed);

  /// No description provided for @profileGoalSectionEyebrow.
  ///
  /// In en, this message translates to:
  /// **'CALORIES'**
  String get profileGoalSectionEyebrow;

  /// No description provided for @profileGoalCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily goal'**
  String get profileGoalCardTitle;

  /// No description provided for @profileGoalCardValue.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal per day'**
  String profileGoalCardValue(int kcal);

  /// No description provided for @profileGoalCardEmptyValue.
  ///
  /// In en, this message translates to:
  /// **'Track your daily progress'**
  String get profileGoalCardEmptyValue;

  /// No description provided for @profileGoalCardActionDefine.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get profileGoalCardActionDefine;

  /// No description provided for @profileGoalCardActionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get profileGoalCardActionEdit;

  /// No description provided for @profileGoalSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily goal'**
  String get profileGoalSheetTitle;

  /// No description provided for @profileGoalSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How many calories do you want to consume per day?'**
  String get profileGoalSheetSubtitle;

  /// No description provided for @profileGoalSheetSuggestionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get profileGoalSheetSuggestionsLabel;

  /// No description provided for @profileGoalSheetSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get profileGoalSheetSave;

  /// No description provided for @profileGoalSheetRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove goal'**
  String get profileGoalSheetRemove;

  /// No description provided for @profileGoalValidationRange.
  ///
  /// In en, this message translates to:
  /// **'Between 500 and 9999'**
  String get profileGoalValidationRange;

  /// No description provided for @profileGroupGoalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Goals & tracking'**
  String get profileGroupGoalsTitle;

  /// No description provided for @profileGroupPreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get profileGroupPreferencesTitle;

  /// No description provided for @profileGroupAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get profileGroupAboutTitle;

  /// No description provided for @profileGoalRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily calorie goal'**
  String get profileGoalRowTitle;

  /// No description provided for @profileGoalRowEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Not set yet'**
  String get profileGoalRowEmptySubtitle;

  /// No description provided for @profileGoalRowValue.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal'**
  String profileGoalRowValue(int kcal);

  /// No description provided for @profileRowAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get profileRowAppearance;

  /// No description provided for @profileRowAppearanceValueDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get profileRowAppearanceValueDark;

  /// No description provided for @profileRowNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get profileRowNotifications;

  /// No description provided for @profileRowLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileRowLanguage;

  /// No description provided for @profileRowLanguageValueAuto.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get profileRowLanguageValueAuto;

  /// No description provided for @profileRowUnits.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get profileRowUnits;

  /// No description provided for @profileRowUnitsValue.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get profileRowUnitsValue;

  /// No description provided for @profileRowPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get profileRowPrivacy;

  /// No description provided for @profileRowTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get profileRowTerms;

  /// No description provided for @profileRowSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & feedback'**
  String get profileRowSupport;

  /// No description provided for @profileComingSoonSnack.
  ///
  /// In en, this message translates to:
  /// **'Coming soon.'**
  String get profileComingSoonSnack;

  /// No description provided for @profileSignOutDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get profileSignOutDialogTitle;

  /// No description provided for @profileSignOutDialogBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to sign in again to access your data.'**
  String get profileSignOutDialogBody;

  /// No description provided for @profileSignOutDialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get profileSignOutDialogCancel;

  /// No description provided for @profileSignOutDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get profileSignOutDialogConfirm;

  /// No description provided for @profileAppVersion.
  ///
  /// In en, this message translates to:
  /// **'{name} v{version} ({build})'**
  String profileAppVersion(String name, String version, String build);

  /// No description provided for @homeOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeOverviewTitle;

  /// No description provided for @homeTodayEyebrow.
  ///
  /// In en, this message translates to:
  /// **'TODAY · {date}'**
  String homeTodayEyebrow(String date);

  /// No description provided for @homeStatusOnTarget.
  ///
  /// In en, this message translates to:
  /// **'On target'**
  String get homeStatusOnTarget;

  /// No description provided for @homeStatusOverGoal.
  ///
  /// In en, this message translates to:
  /// **'Over by {n} kcal'**
  String homeStatusOverGoal(int n);

  /// No description provided for @homeStatusNoGoal.
  ///
  /// In en, this message translates to:
  /// **'Set a goal'**
  String get homeStatusNoGoal;

  /// No description provided for @homeFastingActive.
  ///
  /// In en, this message translates to:
  /// **'Fasting for {duration}'**
  String homeFastingActive(String duration);

  /// No description provided for @homeFastingCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed · {duration}'**
  String homeFastingCompleted(String duration);

  /// No description provided for @homeFastingIdle.
  ///
  /// In en, this message translates to:
  /// **'No fast right now'**
  String get homeFastingIdle;

  /// No description provided for @homeFastingIdleAction.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get homeFastingIdleAction;

  /// No description provided for @homeFastingLast.
  ///
  /// In en, this message translates to:
  /// **'Last · {duration} · {when}'**
  String homeFastingLast(String duration, String when);

  /// No description provided for @homeFastingStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get homeFastingStatusLabel;

  /// No description provided for @homeFastingLastLabel.
  ///
  /// In en, this message translates to:
  /// **'Last'**
  String get homeFastingLastLabel;

  /// No description provided for @homeWeekEyebrow.
  ///
  /// In en, this message translates to:
  /// **'THIS WEEK'**
  String get homeWeekEyebrow;

  /// No description provided for @homeWeekOnTarget.
  ///
  /// In en, this message translates to:
  /// **'{on}/{closed} ON TARGET'**
  String homeWeekOnTarget(int on, int closed);

  /// No description provided for @homeWeekChartGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'goal {kcal}'**
  String homeWeekChartGoalLabel(int kcal);

  /// No description provided for @homeWeekFastingTitle.
  ///
  /// In en, this message translates to:
  /// **'WEEKLY FASTING'**
  String get homeWeekFastingTitle;

  /// No description provided for @homeWeekFastingCompletedLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get homeWeekFastingCompletedLabel;

  /// No description provided for @homeWeekFastingTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get homeWeekFastingTotalLabel;

  /// No description provided for @homeWeekFastingAverageLabel.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get homeWeekFastingAverageLabel;

  /// No description provided for @homeWeekFastingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No fasts this week'**
  String get homeWeekFastingEmpty;

  /// No description provided for @homeWeekdayLetters.
  ///
  /// In en, this message translates to:
  /// **'SMTWTFS'**
  String get homeWeekdayLetters;

  /// No description provided for @homeChartA11y.
  ///
  /// In en, this message translates to:
  /// **'Calorie chart, {on} of {closed} days on target. Selected: {day}, {kcal} kcal.'**
  String homeChartA11y(int on, int closed, String day, int kcal);
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
