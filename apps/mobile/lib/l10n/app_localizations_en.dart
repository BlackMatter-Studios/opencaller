// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'OpenCaller';

  @override
  String get appSubtitle => 'The 100% Free, Private & Community Caller ID';

  @override
  String get statusOnline => 'ONLINE';

  @override
  String get statusOffline => 'OFFLINE MODE';

  @override
  String get statusSyncing => 'SYNCING';

  @override
  String get close => 'Close';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get confirm => 'Confirm';

  @override
  String get continueButton => 'Continue';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get navHistory => 'History';

  @override
  String get navLookup => 'Lookup';

  @override
  String get navShield => 'Shield';

  @override
  String get navPrivacy => 'Privacy';

  @override
  String get historyTitle => 'Call Activity';

  @override
  String get filterAll => 'All';

  @override
  String get filterSpam => 'Spam';

  @override
  String get filterBlocked => 'Blocked';

  @override
  String get filterUnknown => 'Unknown';

  @override
  String get emptyHistoryTitle => 'No calls recorded';

  @override
  String get emptyHistorySubtitle =>
      'Your incoming and screened calls will appear here in real-time.';

  @override
  String get incomingCall => 'Incoming Call';

  @override
  String get outgoingCall => 'Outgoing Call';

  @override
  String get missedCall => 'Missed Call';

  @override
  String get blockedCall => 'Blocked Automatically';

  @override
  String get blockNumber => 'Block Number';

  @override
  String get reportSpam => 'Report Spam';

  @override
  String get lookupTitle => 'Reverse Phone Lookup';

  @override
  String get searchHint => 'Search E.164 phone number...';

  @override
  String get searchButton => 'Search';

  @override
  String get searching => 'Searching...';

  @override
  String couldBeHint(String name) {
    return 'Could be: $name';
  }

  @override
  String probableMatch(String name) {
    return 'Probable: $name';
  }

  @override
  String get verifiedBusiness => 'Verified Business';

  @override
  String get communityVerified => 'Community Consensus';

  @override
  String get badgeCommunityHint => 'COMMUNITY HINT (1 SUGGESTION) 35% conf.';

  @override
  String get badgeProbableMatch => 'PROBABLE CALLER 65% conf.';

  @override
  String get badgeConsensusVerified => 'COMMUNITY CONSENSUS 90% conf.';

  @override
  String get badgeVerifiedBusiness => 'VERIFIED BUSINESS 100% conf.';

  @override
  String get spamSevere => 'SEVERE SPAM DETECTED';

  @override
  String get spamSuspicious => 'SUSPICIOUS NUMBER';

  @override
  String get spamClean => 'CLEAN NUMBER';

  @override
  String spamScore(int score) {
    return 'Spam Score: $score%';
  }

  @override
  String reportsCount(int count) {
    return '$count reports';
  }

  @override
  String reportSheetTitle(String number) {
    return 'Report Number: $number';
  }

  @override
  String get reportReason => 'Reason / Category';

  @override
  String get categoryScam => 'Fraud / Extortion';

  @override
  String get categoryTelemarketing => 'Telemarketing / Sales';

  @override
  String get categoryDebtCollector => 'Aggressive Debt Collector';

  @override
  String get categoryRobocall => 'Automated Robocall';

  @override
  String get submitReport => 'Submit Report';

  @override
  String get reportSubmitted =>
      'Report registered successfully. Thank you for protecting the community!';

  @override
  String get shieldTitle => 'Telephony Defense Shield';

  @override
  String get protectionActive => 'Real-Time Protection Active';

  @override
  String get protectionInactive => 'Protection Disabled';

  @override
  String get screeningRole => 'Native Call Screening';

  @override
  String get screeningRoleGranted => 'Android CallScreening role granted';

  @override
  String get screeningRoleNeeded => 'Tap to activate native call interception';

  @override
  String get grantRoleButton => 'Grant Native Permission';

  @override
  String get spamThreshold => 'Auto-Block Threshold';

  @override
  String spamThresholdDesc(int threshold) {
    return 'Calls with a spam score equal to or higher than $threshold% will be silenced and auto-rejected without ringing.';
  }

  @override
  String get localDatabase => 'Local Offline Database';

  @override
  String localNumbersCount(int count) {
    return '$count known numbers stored on-device';
  }

  @override
  String get syncButton => 'Sync Now';

  @override
  String get syncInProgress => 'Syncing delta updates with federated node...';

  @override
  String get syncSuccess => 'Database synchronized successfully!';

  @override
  String get privacyTitle => 'Sovereignty & Privacy Center';

  @override
  String get privacyManifesto => 'Zero Tracking Guarantee';

  @override
  String get privacyManifestoDesc =>
      'OpenCaller never sells, monetizes, or brokers your contacts or call logs. Your data remains on your device or self-hosted server.';

  @override
  String get sovereigntyTierTitle => 'Current Sovereignty Tier';

  @override
  String get tier0Name => 'Tier 0 — Pure Offline Shield';

  @override
  String get tier0Desc => 'No network calls. Local SQLite query in <10ms.';

  @override
  String get tier1Name => 'Tier 1 — Cloud Reputation';

  @override
  String get tier1Desc =>
      'Queries federated community database for unknown numbers.';

  @override
  String get tier2Name => 'Tier 2 — Hybrid Contributor';

  @override
  String get tier2Desc =>
      'Voluntarily contributes non-favorite contacts to the open directory.';

  @override
  String get changeTier => 'Change Sovereignty Tier';

  @override
  String get reopenOnboarding => 'Revisit Onboarding Setup';

  @override
  String get reopenOnboardingDesc =>
      'Walk through the configuration wizard again at any time.';

  @override
  String get reopenOnboardingButton => 'Launch Wizard';

  @override
  String get languageTitle => 'Application Language';

  @override
  String get languageSystem => 'System Default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get delistTitle => 'Right to be Forgotten (Delist)';

  @override
  String get delistDesc =>
      'Permanently erase your number from OpenCaller\'s global database and blacklist it from re-ingestion.';

  @override
  String get delistNumberHint => 'E.164 Number to remove...';

  @override
  String get delistReasonHint => 'Reason (e.g. Owner requested removal)';

  @override
  String get delistButton => 'Request Permanent Delisting';

  @override
  String get delistSuccess => 'Number successfully delisted and purged.';

  @override
  String get onboardingWelcomeTitle => 'OpenCaller';

  @override
  String get onboardingWelcomeSubtitle =>
      'The 100% Free, Private & Community Caller ID';

  @override
  String get onboardingFeature1Title => 'Instant Local Detection (<10ms)';

  @override
  String get onboardingFeature1Desc =>
      'Your device checks a local SQLite database before the phone rings. Zero latency and zero cloud queries for known numbers.';

  @override
  String get onboardingFeature2Title => 'Zero Commercial Tracking';

  @override
  String get onboardingFeature2Desc =>
      'No Facebook SDKs or Google Ads trackers. Your call logs and contacts are never sold. 100% open source under the MIT License.';

  @override
  String get onboardingFeature3Title => 'Federated Community Power';

  @override
  String get onboardingFeature3Desc =>
      'A decentralized network where users collaborate and verify numbers with graduated democratic consensus.';

  @override
  String get onboardingStartButton => 'Start Configuration';

  @override
  String get onboardingTierHeader => 'Choose Your Privacy Tier';

  @override
  String get onboardingTierNotice =>
      'You can change this at any time in Settings. We will never share your contacts without your explicit consent.';

  @override
  String get onboardingVerifyHeader => 'Account Verification';

  @override
  String get onboardingVerifyDesc =>
      'OpenCaller is 100% community-driven and free. To prevent bots and malicious spoofing, verify your account at zero cost using your preferred method:';

  @override
  String get onboardingVerifyOptionTelegram =>
      'Telegram Bot (@OpenCallerVerifyBot)';

  @override
  String get onboardingVerifyOptionTelegramDesc =>
      'Instant SIM-backed contact share. 100% free and VoIP-proof.';

  @override
  String get onboardingVerifyOptionWhatsApp => 'WhatsApp (Self-Hosted Baileys)';

  @override
  String get onboardingVerifyOptionWhatsAppDesc =>
      'Receive a 6-digit OTP code directly to your WhatsApp.';

  @override
  String get onboardingVerifyOptionAndroid => 'Self-Hosted Android Gateway';

  @override
  String get onboardingVerifyOptionAndroidDesc =>
      'Zero-ring flash call or local SMS from a private Android node.';

  @override
  String get onboardingVerifyOptionPoW =>
      'Anonymous Proof-of-Work (No Phone #)';

  @override
  String get onboardingVerifyOptionPoWDesc =>
      'Hardware device attestation + cryptographic challenge. Complete anonymity.';

  @override
  String get onboardingPhoneNumber => 'Phone Number (E.164)';

  @override
  String get onboardingSendCode => 'Send Code';

  @override
  String get onboardingEnterCode => 'Enter 6-digit OTP';

  @override
  String get onboardingVerifyCode => 'Verify Code';

  @override
  String get onboardingRunPoW => 'Compute Anonymous Challenge';

  @override
  String onboardingVerifiedStatus(String label) {
    return 'Verified: $label';
  }

  @override
  String get onboardingTelephonyHeader => 'Native Call Protection';

  @override
  String get onboardingTelephonyDesc =>
      'To intercept and block fraud calls before your phone vibrates or rings, OpenCaller needs the Android CallScreening role.';

  @override
  String get onboardingGrantRole => 'Enable Call Defense';

  @override
  String get onboardingSkip => 'Skip for Now';

  @override
  String get onboardingReadyHeader => 'You\'re All Set!';

  @override
  String get onboardingReadyDesc =>
      'OpenCaller is configured and ready to defend your incoming calls with full privacy sovereignty.';

  @override
  String get onboardingEnterApp => 'Enter OpenCaller';

  @override
  String get crowdsourcingControls => 'COMMUNITY CROWDSOURCING CONTROLS';

  @override
  String get shareContactsTitle => 'Share Contacts to Community Directory';

  @override
  String get shareContactsDesc =>
      'Help identify local businesses and service drivers. Strict 3-vote consensus required before publication.';

  @override
  String get excludeStarredTitle => 'Exclude Starred / Family Contacts';

  @override
  String get excludeStarredDesc =>
      'Personal friends and favorites are never transmitted under any circumstances.';

  @override
  String get stripMetadataTitle => 'Strip Private Metadata';

  @override
  String get stripMetadataDesc =>
      'Emails, addresses, birthdays, and relationship notes stay strictly on-device.';

  @override
  String get consentModalTitle => 'Crowdsourcing Privacy Agreement';

  @override
  String get consentModalDesc =>
      '• Strict Consensus: A name is only made visible once 3 or more independent users suggest it.\n• Zero Personal Data: Emails, photos, and physical addresses are NEVER accessed or transmitted.\n• Right to Opt-Out: Anyone can delist their number at any time.';

  @override
  String get consentModalAgree => 'I Understand & Consent';

  @override
  String get consentModalFeedback =>
      'Community sharing enabled with privacy safeguards.';

  @override
  String get shieldHeaderTitle => 'Native Call Shield';

  @override
  String get shieldHeaderDesc =>
      'OpenCaller runs locally to screen incoming calls with zero latency and zero data leakage.';

  @override
  String get shieldAndroidRoleTitle => 'Android Call Screening Role';

  @override
  String get shieldStatusActive => 'ACTIVE';

  @override
  String get shieldStatusActionRequired => 'ACTION REQUIRED';

  @override
  String get shieldStatusPending => 'PENDING';

  @override
  String get shieldAndroidRoleDesc =>
      'Android requires granting the Call Screening role to allow OpenCaller to query the local SQLite database synchronously (<150ms) and silence or block spam calls before your phone rings.';

  @override
  String get shieldSetRoleButton => 'Set as Call Screening App';

  @override
  String get shieldActiveOnDevice =>
      'Real-time screening active on this device';

  @override
  String get shieldIOSRoleTitle => 'iOS Call Directory Extension';

  @override
  String get shieldIOSEnabled => 'ENABLED';

  @override
  String get shieldIOSSetupNeeded => 'SETUP NEEDED';

  @override
  String get shieldIOSDesc =>
      'On iOS, OpenCaller loads pre-sorted spam and community numbers into the iOS telephony database via CallKit. Apple requires toggling this extension once in System Settings.';

  @override
  String get shieldIOSInstructions =>
      'Instructions:\n1. Tap \"Open iPhone Settings\" below.\n2. Go to Phone > Call Blocking & Identification.\n3. Turn ON \"OpenCaller\".';

  @override
  String get shieldIOSOpenSettings => 'Open iPhone Settings';

  @override
  String get shieldIOSRefresh => 'Refresh Status / Reload Extension';

  @override
  String get shieldDeviceRequirement =>
      'Telephony screening requires a physical Android or iOS device.';

  @override
  String get unidentifiedCaller => 'Unidentified Caller';

  @override
  String get noRecords => 'NO RECORDS';

  @override
  String get protectedDelisted => 'PROTECTED';

  @override
  String get privateDelistedNumber => 'Private / Delisted Number';

  @override
  String get delistedNote => 'This number exercised its right to be forgotten.';

  @override
  String get communityHintNote =>
      'Suggested by 1 community contributor. Use with caution.';

  @override
  String get probableMatchNote => 'Confirmed by 2 independent contributors.';

  @override
  String get consensusVerifiedNote =>
      'Community consensus of 3+ contributors reached.';

  @override
  String get metricCategory => 'Category';

  @override
  String get metricReports => 'Reports';

  @override
  String get statusCleanBadge => 'CLEAN';

  @override
  String get statusBlocked => 'BLOCKED';

  @override
  String get unknownCaller => 'Unknown Caller';

  @override
  String syncCompleted(int count) {
    return 'Sync complete! Updated $count phone numbers.';
  }

  @override
  String syncFailed(String error) {
    return 'Sync failed: $error';
  }

  @override
  String get syncTooltip => 'Sync Local Spam Database';

  @override
  String get cryptoChallengeTitle => 'Local Cryptographic Verification';

  @override
  String get cryptoChallengeDesc =>
      'No phone number required. Solves a fast SHA-256 Proof-of-Work challenge (~50ms) on your device to prove you are a genuine human client.';

  @override
  String get generateAnonymousCredential => 'Generate Anonymous Credential';

  @override
  String get enterPhoneNumber => 'Enter Your Phone Number';

  @override
  String get requestOtpButton => 'Request OTP Code';

  @override
  String get otpSixDigits => '6-Digit OTP Code:';

  @override
  String get verifyCodeButton => 'Verify Code';

  @override
  String get nextStepButton => 'Next Step';

  @override
  String get androidCallScreeningServiceDesc =>
      'Enables Android CallScreeningService to intercept incoming calls in real-time with zero latency.';

  @override
  String get callScreeningActive => 'Filter active and ready on this device';

  @override
  String get summaryTierLabel => 'Privacy Tier';

  @override
  String get summaryShieldLabel => 'Shield Status';

  @override
  String get summaryVerifyLabel => 'Verification';

  @override
  String get summaryConfigurable => 'Configurable in Settings';

  @override
  String get summaryGuestMode => 'Guest Mode';

  @override
  String get summaryVerified => 'Verified';
}
