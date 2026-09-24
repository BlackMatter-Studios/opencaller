import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
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
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('es'),
    Locale('pt'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'OpenCaller'**
  String get appName;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The 100% Free, Private & Community Caller ID'**
  String get appSubtitle;

  /// No description provided for @statusOnline.
  ///
  /// In en, this message translates to:
  /// **'ONLINE'**
  String get statusOnline;

  /// No description provided for @statusOffline.
  ///
  /// In en, this message translates to:
  /// **'OFFLINE MODE'**
  String get statusOffline;

  /// No description provided for @statusSyncing.
  ///
  /// In en, this message translates to:
  /// **'SYNCING'**
  String get statusSyncing;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navLookup.
  ///
  /// In en, this message translates to:
  /// **'Lookup'**
  String get navLookup;

  /// No description provided for @navShield.
  ///
  /// In en, this message translates to:
  /// **'Shield'**
  String get navShield;

  /// No description provided for @navPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get navPrivacy;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Call Activity'**
  String get historyTitle;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get filterSpam;

  /// No description provided for @filterBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get filterBlocked;

  /// No description provided for @filterUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get filterUnknown;

  /// No description provided for @emptyHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'No calls recorded'**
  String get emptyHistoryTitle;

  /// No description provided for @emptyHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your incoming and screened calls will appear here in real-time.'**
  String get emptyHistorySubtitle;

  /// No description provided for @incomingCall.
  ///
  /// In en, this message translates to:
  /// **'Incoming Call'**
  String get incomingCall;

  /// No description provided for @outgoingCall.
  ///
  /// In en, this message translates to:
  /// **'Outgoing Call'**
  String get outgoingCall;

  /// No description provided for @missedCall.
  ///
  /// In en, this message translates to:
  /// **'Missed Call'**
  String get missedCall;

  /// No description provided for @blockedCall.
  ///
  /// In en, this message translates to:
  /// **'Blocked Automatically'**
  String get blockedCall;

  /// No description provided for @blockNumber.
  ///
  /// In en, this message translates to:
  /// **'Block Number'**
  String get blockNumber;

  /// No description provided for @reportSpam.
  ///
  /// In en, this message translates to:
  /// **'Report Spam'**
  String get reportSpam;

  /// No description provided for @lookupTitle.
  ///
  /// In en, this message translates to:
  /// **'Reverse Phone Lookup'**
  String get lookupTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search E.164 phone number...'**
  String get searchHint;

  /// No description provided for @searchButton.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchButton;

  /// No description provided for @searching.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searching;

  /// No description provided for @couldBeHint.
  ///
  /// In en, this message translates to:
  /// **'Could be: {name}'**
  String couldBeHint(String name);

  /// No description provided for @probableMatch.
  ///
  /// In en, this message translates to:
  /// **'Probable: {name}'**
  String probableMatch(String name);

  /// No description provided for @verifiedBusiness.
  ///
  /// In en, this message translates to:
  /// **'Verified Business'**
  String get verifiedBusiness;

  /// No description provided for @communityVerified.
  ///
  /// In en, this message translates to:
  /// **'Community Consensus'**
  String get communityVerified;

  /// No description provided for @badgeCommunityHint.
  ///
  /// In en, this message translates to:
  /// **'COMMUNITY HINT (1 SUGGESTION) 35% conf.'**
  String get badgeCommunityHint;

  /// No description provided for @badgeProbableMatch.
  ///
  /// In en, this message translates to:
  /// **'PROBABLE CALLER 65% conf.'**
  String get badgeProbableMatch;

  /// No description provided for @badgeConsensusVerified.
  ///
  /// In en, this message translates to:
  /// **'COMMUNITY CONSENSUS 90% conf.'**
  String get badgeConsensusVerified;

  /// No description provided for @badgeVerifiedBusiness.
  ///
  /// In en, this message translates to:
  /// **'VERIFIED BUSINESS 100% conf.'**
  String get badgeVerifiedBusiness;

  /// No description provided for @spamSevere.
  ///
  /// In en, this message translates to:
  /// **'SEVERE SPAM DETECTED'**
  String get spamSevere;

  /// No description provided for @spamSuspicious.
  ///
  /// In en, this message translates to:
  /// **'SUSPICIOUS NUMBER'**
  String get spamSuspicious;

  /// No description provided for @spamClean.
  ///
  /// In en, this message translates to:
  /// **'CLEAN NUMBER'**
  String get spamClean;

  /// No description provided for @spamScore.
  ///
  /// In en, this message translates to:
  /// **'Spam Score: {score}%'**
  String spamScore(int score);

  /// No description provided for @reportsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} reports'**
  String reportsCount(int count);

  /// No description provided for @reportSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Report Number: {number}'**
  String reportSheetTitle(String number);

  /// No description provided for @reportReason.
  ///
  /// In en, this message translates to:
  /// **'Reason / Category'**
  String get reportReason;

  /// No description provided for @categoryScam.
  ///
  /// In en, this message translates to:
  /// **'Fraud / Extortion'**
  String get categoryScam;

  /// No description provided for @categoryTelemarketing.
  ///
  /// In en, this message translates to:
  /// **'Telemarketing / Sales'**
  String get categoryTelemarketing;

  /// No description provided for @categoryDebtCollector.
  ///
  /// In en, this message translates to:
  /// **'Aggressive Debt Collector'**
  String get categoryDebtCollector;

  /// No description provided for @categoryRobocall.
  ///
  /// In en, this message translates to:
  /// **'Automated Robocall'**
  String get categoryRobocall;

  /// No description provided for @submitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get submitReport;

  /// No description provided for @reportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report registered successfully. Thank you for protecting the community!'**
  String get reportSubmitted;

  /// No description provided for @shieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Telephony Defense Shield'**
  String get shieldTitle;

  /// No description provided for @protectionActive.
  ///
  /// In en, this message translates to:
  /// **'Real-Time Protection Active'**
  String get protectionActive;

  /// No description provided for @protectionInactive.
  ///
  /// In en, this message translates to:
  /// **'Protection Disabled'**
  String get protectionInactive;

  /// No description provided for @screeningRole.
  ///
  /// In en, this message translates to:
  /// **'Native Call Screening'**
  String get screeningRole;

  /// No description provided for @screeningRoleGranted.
  ///
  /// In en, this message translates to:
  /// **'Android CallScreening role granted'**
  String get screeningRoleGranted;

  /// No description provided for @screeningRoleNeeded.
  ///
  /// In en, this message translates to:
  /// **'Tap to activate native call interception'**
  String get screeningRoleNeeded;

  /// No description provided for @grantRoleButton.
  ///
  /// In en, this message translates to:
  /// **'Grant Native Permission'**
  String get grantRoleButton;

  /// No description provided for @spamThreshold.
  ///
  /// In en, this message translates to:
  /// **'Auto-Block Threshold'**
  String get spamThreshold;

  /// No description provided for @spamThresholdDesc.
  ///
  /// In en, this message translates to:
  /// **'Calls with a spam score equal to or higher than {threshold}% will be silenced and auto-rejected without ringing.'**
  String spamThresholdDesc(int threshold);

  /// No description provided for @localDatabase.
  ///
  /// In en, this message translates to:
  /// **'Local Offline Database'**
  String get localDatabase;

  /// No description provided for @localNumbersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} known numbers stored on-device'**
  String localNumbersCount(int count);

  /// No description provided for @syncButton.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncButton;

  /// No description provided for @syncInProgress.
  ///
  /// In en, this message translates to:
  /// **'Syncing delta updates with federated node...'**
  String get syncInProgress;

  /// No description provided for @syncSuccess.
  ///
  /// In en, this message translates to:
  /// **'Database synchronized successfully!'**
  String get syncSuccess;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Sovereignty & Privacy Center'**
  String get privacyTitle;

  /// No description provided for @privacyManifesto.
  ///
  /// In en, this message translates to:
  /// **'Zero Tracking Guarantee'**
  String get privacyManifesto;

  /// No description provided for @privacyManifestoDesc.
  ///
  /// In en, this message translates to:
  /// **'OpenCaller never sells, monetizes, or brokers your contacts or call logs. Your data remains on your device or self-hosted server.'**
  String get privacyManifestoDesc;

  /// No description provided for @sovereigntyTierTitle.
  ///
  /// In en, this message translates to:
  /// **'Current Sovereignty Tier'**
  String get sovereigntyTierTitle;

  /// No description provided for @tier0Name.
  ///
  /// In en, this message translates to:
  /// **'Tier 0 — Pure Offline Shield'**
  String get tier0Name;

  /// No description provided for @tier0Desc.
  ///
  /// In en, this message translates to:
  /// **'No network calls. Local SQLite query in <10ms.'**
  String get tier0Desc;

  /// No description provided for @tier1Name.
  ///
  /// In en, this message translates to:
  /// **'Tier 1 — Cloud Reputation'**
  String get tier1Name;

  /// No description provided for @tier1Desc.
  ///
  /// In en, this message translates to:
  /// **'Queries federated community database for unknown numbers.'**
  String get tier1Desc;

  /// No description provided for @tier2Name.
  ///
  /// In en, this message translates to:
  /// **'Tier 2 — Hybrid Contributor'**
  String get tier2Name;

  /// No description provided for @tier2Desc.
  ///
  /// In en, this message translates to:
  /// **'Voluntarily contributes non-favorite contacts to the open directory.'**
  String get tier2Desc;

  /// No description provided for @changeTier.
  ///
  /// In en, this message translates to:
  /// **'Change Sovereignty Tier'**
  String get changeTier;

  /// No description provided for @reopenOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Revisit Onboarding Setup'**
  String get reopenOnboarding;

  /// No description provided for @reopenOnboardingDesc.
  ///
  /// In en, this message translates to:
  /// **'Walk through the configuration wizard again at any time.'**
  String get reopenOnboardingDesc;

  /// No description provided for @reopenOnboardingButton.
  ///
  /// In en, this message translates to:
  /// **'Launch Wizard'**
  String get reopenOnboardingButton;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Application Language'**
  String get languageTitle;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @languagePortuguese.
  ///
  /// In en, this message translates to:
  /// **'Português'**
  String get languagePortuguese;

  /// No description provided for @delistTitle.
  ///
  /// In en, this message translates to:
  /// **'Right to be Forgotten (Delist)'**
  String get delistTitle;

  /// No description provided for @delistDesc.
  ///
  /// In en, this message translates to:
  /// **'Permanently erase your number from OpenCaller\'s global database and blacklist it from re-ingestion.'**
  String get delistDesc;

  /// No description provided for @delistNumberHint.
  ///
  /// In en, this message translates to:
  /// **'E.164 Number to remove...'**
  String get delistNumberHint;

  /// No description provided for @delistReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Reason (e.g. Owner requested removal)'**
  String get delistReasonHint;

  /// No description provided for @delistButton.
  ///
  /// In en, this message translates to:
  /// **'Request Permanent Delisting'**
  String get delistButton;

  /// No description provided for @delistSuccess.
  ///
  /// In en, this message translates to:
  /// **'Number successfully delisted and purged.'**
  String get delistSuccess;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'OpenCaller'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The 100% Free, Private & Community Caller ID'**
  String get onboardingWelcomeSubtitle;

  /// No description provided for @onboardingFeature1Title.
  ///
  /// In en, this message translates to:
  /// **'Instant Local Detection (<10ms)'**
  String get onboardingFeature1Title;

  /// No description provided for @onboardingFeature1Desc.
  ///
  /// In en, this message translates to:
  /// **'Your device checks a local SQLite database before the phone rings. Zero latency and zero cloud queries for known numbers.'**
  String get onboardingFeature1Desc;

  /// No description provided for @onboardingFeature2Title.
  ///
  /// In en, this message translates to:
  /// **'Zero Commercial Tracking'**
  String get onboardingFeature2Title;

  /// No description provided for @onboardingFeature2Desc.
  ///
  /// In en, this message translates to:
  /// **'No Facebook SDKs or Google Ads trackers. Your call logs and contacts are never sold. 100% open source under the MIT License.'**
  String get onboardingFeature2Desc;

  /// No description provided for @onboardingFeature3Title.
  ///
  /// In en, this message translates to:
  /// **'Federated Community Power'**
  String get onboardingFeature3Title;

  /// No description provided for @onboardingFeature3Desc.
  ///
  /// In en, this message translates to:
  /// **'A decentralized network where users collaborate and verify numbers with graduated democratic consensus.'**
  String get onboardingFeature3Desc;

  /// No description provided for @onboardingStartButton.
  ///
  /// In en, this message translates to:
  /// **'Start Configuration'**
  String get onboardingStartButton;

  /// No description provided for @onboardingTierHeader.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Privacy Tier'**
  String get onboardingTierHeader;

  /// No description provided for @onboardingTierNotice.
  ///
  /// In en, this message translates to:
  /// **'You can change this at any time in Settings. We will never share your contacts without your explicit consent.'**
  String get onboardingTierNotice;

  /// No description provided for @onboardingVerifyHeader.
  ///
  /// In en, this message translates to:
  /// **'Account Verification'**
  String get onboardingVerifyHeader;

  /// No description provided for @onboardingVerifyDesc.
  ///
  /// In en, this message translates to:
  /// **'OpenCaller is 100% community-driven and free. To prevent bots and malicious spoofing, verify your account at zero cost using your preferred method:'**
  String get onboardingVerifyDesc;

  /// No description provided for @onboardingVerifyOptionTelegram.
  ///
  /// In en, this message translates to:
  /// **'Telegram Bot (@OpenCallerVerifyBot)'**
  String get onboardingVerifyOptionTelegram;

  /// No description provided for @onboardingVerifyOptionTelegramDesc.
  ///
  /// In en, this message translates to:
  /// **'Instant SIM-backed contact share. 100% free and VoIP-proof.'**
  String get onboardingVerifyOptionTelegramDesc;

  /// No description provided for @onboardingVerifyOptionWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp (Self-Hosted Baileys)'**
  String get onboardingVerifyOptionWhatsApp;

  /// No description provided for @onboardingVerifyOptionWhatsAppDesc.
  ///
  /// In en, this message translates to:
  /// **'Receive a 6-digit OTP code directly to your WhatsApp.'**
  String get onboardingVerifyOptionWhatsAppDesc;

  /// No description provided for @onboardingVerifyOptionAndroid.
  ///
  /// In en, this message translates to:
  /// **'Self-Hosted Android Gateway'**
  String get onboardingVerifyOptionAndroid;

  /// No description provided for @onboardingVerifyOptionAndroidDesc.
  ///
  /// In en, this message translates to:
  /// **'Zero-ring flash call or local SMS from a private Android node.'**
  String get onboardingVerifyOptionAndroidDesc;

  /// No description provided for @onboardingVerifyOptionPoW.
  ///
  /// In en, this message translates to:
  /// **'Anonymous Proof-of-Work (No Phone #)'**
  String get onboardingVerifyOptionPoW;

  /// No description provided for @onboardingVerifyOptionPoWDesc.
  ///
  /// In en, this message translates to:
  /// **'Hardware device attestation + cryptographic challenge. Complete anonymity.'**
  String get onboardingVerifyOptionPoWDesc;

  /// No description provided for @onboardingPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number (E.164)'**
  String get onboardingPhoneNumber;

  /// No description provided for @onboardingSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get onboardingSendCode;

  /// No description provided for @onboardingEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit OTP'**
  String get onboardingEnterCode;

  /// No description provided for @onboardingVerifyCode.
  ///
  /// In en, this message translates to:
  /// **'Verify Code'**
  String get onboardingVerifyCode;

  /// No description provided for @onboardingRunPoW.
  ///
  /// In en, this message translates to:
  /// **'Compute Anonymous Challenge'**
  String get onboardingRunPoW;

  /// No description provided for @onboardingVerifiedStatus.
  ///
  /// In en, this message translates to:
  /// **'Verified: {label}'**
  String onboardingVerifiedStatus(String label);

  /// No description provided for @onboardingTelephonyHeader.
  ///
  /// In en, this message translates to:
  /// **'Native Call Protection'**
  String get onboardingTelephonyHeader;

  /// No description provided for @onboardingTelephonyDesc.
  ///
  /// In en, this message translates to:
  /// **'To intercept and block fraud calls before your phone vibrates or rings, OpenCaller needs the Android CallScreening role.'**
  String get onboardingTelephonyDesc;

  /// No description provided for @onboardingGrantRole.
  ///
  /// In en, this message translates to:
  /// **'Enable Call Defense'**
  String get onboardingGrantRole;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip for Now'**
  String get onboardingSkip;

  /// No description provided for @onboardingReadyHeader.
  ///
  /// In en, this message translates to:
  /// **'You\'re All Set!'**
  String get onboardingReadyHeader;

  /// No description provided for @onboardingReadyDesc.
  ///
  /// In en, this message translates to:
  /// **'OpenCaller is configured and ready to defend your incoming calls with full privacy sovereignty.'**
  String get onboardingReadyDesc;

  /// No description provided for @onboardingEnterApp.
  ///
  /// In en, this message translates to:
  /// **'Enter OpenCaller'**
  String get onboardingEnterApp;

  /// No description provided for @crowdsourcingControls.
  ///
  /// In en, this message translates to:
  /// **'COMMUNITY CROWDSOURCING CONTROLS'**
  String get crowdsourcingControls;

  /// No description provided for @shareContactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Share Contacts to Community Directory'**
  String get shareContactsTitle;

  /// No description provided for @shareContactsDesc.
  ///
  /// In en, this message translates to:
  /// **'Help identify local businesses and service drivers. Strict 3-vote consensus required before publication.'**
  String get shareContactsDesc;

  /// No description provided for @excludeStarredTitle.
  ///
  /// In en, this message translates to:
  /// **'Exclude Starred / Family Contacts'**
  String get excludeStarredTitle;

  /// No description provided for @excludeStarredDesc.
  ///
  /// In en, this message translates to:
  /// **'Personal friends and favorites are never transmitted under any circumstances.'**
  String get excludeStarredDesc;

  /// No description provided for @stripMetadataTitle.
  ///
  /// In en, this message translates to:
  /// **'Strip Private Metadata'**
  String get stripMetadataTitle;

  /// No description provided for @stripMetadataDesc.
  ///
  /// In en, this message translates to:
  /// **'Emails, addresses, birthdays, and relationship notes stay strictly on-device.'**
  String get stripMetadataDesc;

  /// No description provided for @consentModalTitle.
  ///
  /// In en, this message translates to:
  /// **'Crowdsourcing Privacy Agreement'**
  String get consentModalTitle;

  /// No description provided for @consentModalDesc.
  ///
  /// In en, this message translates to:
  /// **'• Strict Consensus: A name is only made visible once 3 or more independent users suggest it.\n• Zero Personal Data: Emails, photos, and physical addresses are NEVER accessed or transmitted.\n• Right to Opt-Out: Anyone can delist their number at any time.'**
  String get consentModalDesc;

  /// No description provided for @consentModalAgree.
  ///
  /// In en, this message translates to:
  /// **'I Understand & Consent'**
  String get consentModalAgree;

  /// No description provided for @consentModalFeedback.
  ///
  /// In en, this message translates to:
  /// **'Community sharing enabled with privacy safeguards.'**
  String get consentModalFeedback;

  /// No description provided for @shieldHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Native Call Shield'**
  String get shieldHeaderTitle;

  /// No description provided for @shieldHeaderDesc.
  ///
  /// In en, this message translates to:
  /// **'OpenCaller runs locally to screen incoming calls with zero latency and zero data leakage.'**
  String get shieldHeaderDesc;

  /// No description provided for @shieldAndroidRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Android Call Screening Role'**
  String get shieldAndroidRoleTitle;

  /// No description provided for @shieldStatusActive.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get shieldStatusActive;

  /// No description provided for @shieldStatusActionRequired.
  ///
  /// In en, this message translates to:
  /// **'ACTION REQUIRED'**
  String get shieldStatusActionRequired;

  /// No description provided for @shieldStatusPending.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get shieldStatusPending;

  /// No description provided for @shieldAndroidRoleDesc.
  ///
  /// In en, this message translates to:
  /// **'Android requires granting the Call Screening role to allow OpenCaller to query the local SQLite database synchronously (<150ms) and silence or block spam calls before your phone rings.'**
  String get shieldAndroidRoleDesc;

  /// No description provided for @shieldSetRoleButton.
  ///
  /// In en, this message translates to:
  /// **'Set as Call Screening App'**
  String get shieldSetRoleButton;

  /// No description provided for @shieldActiveOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Real-time screening active on this device'**
  String get shieldActiveOnDevice;

  /// No description provided for @shieldIOSRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'iOS Call Directory Extension'**
  String get shieldIOSRoleTitle;

  /// No description provided for @shieldIOSEnabled.
  ///
  /// In en, this message translates to:
  /// **'ENABLED'**
  String get shieldIOSEnabled;

  /// No description provided for @shieldIOSSetupNeeded.
  ///
  /// In en, this message translates to:
  /// **'SETUP NEEDED'**
  String get shieldIOSSetupNeeded;

  /// No description provided for @shieldIOSDesc.
  ///
  /// In en, this message translates to:
  /// **'On iOS, OpenCaller loads pre-sorted spam and community numbers into the iOS telephony database via CallKit. Apple requires toggling this extension once in System Settings.'**
  String get shieldIOSDesc;

  /// No description provided for @shieldIOSInstructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions:\n1. Tap \"Open iPhone Settings\" below.\n2. Go to Phone > Call Blocking & Identification.\n3. Turn ON \"OpenCaller\".'**
  String get shieldIOSInstructions;

  /// No description provided for @shieldIOSOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open iPhone Settings'**
  String get shieldIOSOpenSettings;

  /// No description provided for @shieldIOSRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh Status / Reload Extension'**
  String get shieldIOSRefresh;

  /// No description provided for @shieldDeviceRequirement.
  ///
  /// In en, this message translates to:
  /// **'Telephony screening requires a physical Android or iOS device.'**
  String get shieldDeviceRequirement;

  /// No description provided for @unidentifiedCaller.
  ///
  /// In en, this message translates to:
  /// **'Unidentified Caller'**
  String get unidentifiedCaller;

  /// No description provided for @noRecords.
  ///
  /// In en, this message translates to:
  /// **'NO RECORDS'**
  String get noRecords;

  /// No description provided for @protectedDelisted.
  ///
  /// In en, this message translates to:
  /// **'PROTECTED'**
  String get protectedDelisted;

  /// No description provided for @privateDelistedNumber.
  ///
  /// In en, this message translates to:
  /// **'Private / Delisted Number'**
  String get privateDelistedNumber;

  /// No description provided for @delistedNote.
  ///
  /// In en, this message translates to:
  /// **'This number exercised its right to be forgotten.'**
  String get delistedNote;

  /// No description provided for @communityHintNote.
  ///
  /// In en, this message translates to:
  /// **'Suggested by 1 community contributor. Use with caution.'**
  String get communityHintNote;

  /// No description provided for @probableMatchNote.
  ///
  /// In en, this message translates to:
  /// **'Confirmed by 2 independent contributors.'**
  String get probableMatchNote;

  /// No description provided for @consensusVerifiedNote.
  ///
  /// In en, this message translates to:
  /// **'Community consensus of 3+ contributors reached.'**
  String get consensusVerifiedNote;

  /// No description provided for @metricCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get metricCategory;

  /// No description provided for @metricReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get metricReports;

  /// No description provided for @statusCleanBadge.
  ///
  /// In en, this message translates to:
  /// **'CLEAN'**
  String get statusCleanBadge;

  /// No description provided for @statusBlocked.
  ///
  /// In en, this message translates to:
  /// **'BLOCKED'**
  String get statusBlocked;

  /// No description provided for @unknownCaller.
  ///
  /// In en, this message translates to:
  /// **'Unknown Caller'**
  String get unknownCaller;

  /// No description provided for @syncCompleted.
  ///
  /// In en, this message translates to:
  /// **'Sync complete! Updated {count} phone numbers.'**
  String syncCompleted(int count);

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed: {error}'**
  String syncFailed(String error);

  /// No description provided for @syncTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sync Local Spam Database'**
  String get syncTooltip;

  /// No description provided for @cryptoChallengeTitle.
  ///
  /// In en, this message translates to:
  /// **'Local Cryptographic Verification'**
  String get cryptoChallengeTitle;

  /// No description provided for @cryptoChallengeDesc.
  ///
  /// In en, this message translates to:
  /// **'No phone number required. Solves a fast SHA-256 Proof-of-Work challenge (~50ms) on your device to prove you are a genuine human client.'**
  String get cryptoChallengeDesc;

  /// No description provided for @generateAnonymousCredential.
  ///
  /// In en, this message translates to:
  /// **'Generate Anonymous Credential'**
  String get generateAnonymousCredential;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter Your Phone Number'**
  String get enterPhoneNumber;

  /// No description provided for @requestOtpButton.
  ///
  /// In en, this message translates to:
  /// **'Request OTP Code'**
  String get requestOtpButton;

  /// No description provided for @otpSixDigits.
  ///
  /// In en, this message translates to:
  /// **'6-Digit OTP Code:'**
  String get otpSixDigits;

  /// No description provided for @verifyCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Verify Code'**
  String get verifyCodeButton;

  /// No description provided for @nextStepButton.
  ///
  /// In en, this message translates to:
  /// **'Next Step'**
  String get nextStepButton;

  /// No description provided for @androidCallScreeningServiceDesc.
  ///
  /// In en, this message translates to:
  /// **'Enables Android CallScreeningService to intercept incoming calls in real-time with zero latency.'**
  String get androidCallScreeningServiceDesc;

  /// No description provided for @callScreeningActive.
  ///
  /// In en, this message translates to:
  /// **'Filter active and ready on this device'**
  String get callScreeningActive;

  /// No description provided for @summaryTierLabel.
  ///
  /// In en, this message translates to:
  /// **'Privacy Tier'**
  String get summaryTierLabel;

  /// No description provided for @summaryShieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Shield Status'**
  String get summaryShieldLabel;

  /// No description provided for @summaryVerifyLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get summaryVerifyLabel;

  /// No description provided for @summaryConfigurable.
  ///
  /// In en, this message translates to:
  /// **'Configurable in Settings'**
  String get summaryConfigurable;

  /// No description provided for @summaryGuestMode.
  ///
  /// In en, this message translates to:
  /// **'Guest Mode'**
  String get summaryGuestMode;

  /// No description provided for @summaryVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get summaryVerified;
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
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
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
