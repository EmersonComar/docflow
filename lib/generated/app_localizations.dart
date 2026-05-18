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
    Locale('pt')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'DocFlow'**
  String get appTitle;

  /// No description provided for @newsTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s New'**
  String get newsTitle;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @noTagsFound.
  ///
  /// In en, this message translates to:
  /// **'No tags found.'**
  String get noTagsFound;

  /// No description provided for @copyCodeSnack.
  ///
  /// In en, this message translates to:
  /// **'Code copied!'**
  String get copyCodeSnack;

  /// No description provided for @copyCodeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get copyCodeTooltip;

  /// No description provided for @editTemplate.
  ///
  /// In en, this message translates to:
  /// **'Edit Template'**
  String get editTemplate;

  /// No description provided for @newTemplate.
  ///
  /// In en, this message translates to:
  /// **'New Template'**
  String get newTemplate;

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

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @contentLabel.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get contentLabel;

  /// No description provided for @pleaseInsertTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get pleaseInsertTitle;

  /// No description provided for @pleaseInsertContent.
  ///
  /// In en, this message translates to:
  /// **'Please enter the content'**
  String get pleaseInsertContent;

  /// No description provided for @tagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tags (comma separated)'**
  String get tagsLabel;

  /// No description provided for @importMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Import markdown'**
  String get importMarkdown;

  /// No description provided for @importMarkdownError.
  ///
  /// In en, this message translates to:
  /// **'Failed to read the markdown file. Please make sure it is a valid UTF-8 file.'**
  String get importMarkdownError;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @noTemplatesFound.
  ///
  /// In en, this message translates to:
  /// **'No templates found.'**
  String get noTemplatesFound;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get confirmDeleteTitle;

  /// No description provided for @confirmDeleteContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the template \"{title}\"?'**
  String confirmDeleteContent(String title);

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @contentCopied.
  ///
  /// In en, this message translates to:
  /// **'Content copied!'**
  String get contentCopied;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @changeTheme.
  ///
  /// In en, this message translates to:
  /// **'Change Theme'**
  String get changeTheme;

  /// No description provided for @newTemplateFab.
  ///
  /// In en, this message translates to:
  /// **'New Template'**
  String get newTemplateFab;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error: {error}'**
  String unexpectedError(String error);

  /// No description provided for @loadMoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load more templates: {error}'**
  String loadMoreFailed(String error);

  /// No description provided for @databaseInitializationFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize database: {error}'**
  String databaseInitializationFailed(String error);

  /// No description provided for @createTemplateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create template: {error}'**
  String createTemplateFailed(String error);

  /// No description provided for @templateIdCannotBeNull.
  ///
  /// In en, this message translates to:
  /// **'Template ID cannot be null'**
  String get templateIdCannotBeNull;

  /// No description provided for @updateTemplateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update template: {error}'**
  String updateTemplateFailed(String error);

  /// No description provided for @deleteTemplateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete template: {error}'**
  String deleteTemplateFailed(String error);

  /// No description provided for @loadTemplatesFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load templates: {error}'**
  String loadTemplatesFailed(String error);

  /// No description provided for @loadTagsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load tags: {error}'**
  String loadTagsFailed(String error);

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred'**
  String get unknownError;

  /// No description provided for @fillVariablesTitle.
  ///
  /// In en, this message translates to:
  /// **'Fill Variables'**
  String get fillVariablesTitle;

  /// No description provided for @confirmCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get confirmCopy;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get changeLanguage;

  /// No description provided for @enableMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Enable Markdown'**
  String get enableMarkdown;

  /// No description provided for @enableSnippets.
  ///
  /// In en, this message translates to:
  /// **'Enable Snippets'**
  String get enableSnippets;

  /// No description provided for @templateSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get templateSettings;

  /// No description provided for @markdownPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get markdownPreview;

  /// No description provided for @plainTextPreview.
  ///
  /// In en, this message translates to:
  /// **'Plain text'**
  String get plainTextPreview;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to DocFlow!'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'All your templates in one place.\nChoose where to store your data file.'**
  String get welcomeSubtitle;

  /// No description provided for @createNewDatabase.
  ///
  /// In en, this message translates to:
  /// **'Create new file'**
  String get createNewDatabase;

  /// No description provided for @openExistingDatabase.
  ///
  /// In en, this message translates to:
  /// **'Open existing file'**
  String get openExistingDatabase;

  /// No description provided for @openAnotherFile.
  ///
  /// In en, this message translates to:
  /// **'Open another file'**
  String get openAnotherFile;

  /// No description provided for @currentFile.
  ///
  /// In en, this message translates to:
  /// **'File: {name}'**
  String currentFile(String name);

  /// No description provided for @databaseNotFound.
  ///
  /// In en, this message translates to:
  /// **'File not found. Please choose another.'**
  String get databaseNotFound;

  /// No description provided for @selectSaveLocation.
  ///
  /// In en, this message translates to:
  /// **'Choose save location'**
  String get selectSaveLocation;

  /// No description provided for @selectDatabaseFile.
  ///
  /// In en, this message translates to:
  /// **'Select database file'**
  String get selectDatabaseFile;

  /// No description provided for @invalidDatabaseFile.
  ///
  /// In en, this message translates to:
  /// **'The selected file is not a valid database.'**
  String get invalidDatabaseFile;

  /// No description provided for @postgresConnectionTitle.
  ///
  /// In en, this message translates to:
  /// **'PostgreSQL Connection'**
  String get postgresConnectionTitle;

  /// No description provided for @postgresConnectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to an external PostgreSQL database'**
  String get postgresConnectionSubtitle;

  /// No description provided for @serverIpLabel.
  ///
  /// In en, this message translates to:
  /// **'Server IP / Hostname'**
  String get serverIpLabel;

  /// No description provided for @portLabel.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get portLabel;

  /// No description provided for @databaseLabel.
  ///
  /// In en, this message translates to:
  /// **'Database'**
  String get databaseLabel;

  /// No description provided for @usernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @connectButton.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connectButton;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connecting;

  /// No description provided for @allFieldsRequired.
  ///
  /// In en, this message translates to:
  /// **'All fields are required'**
  String get allFieldsRequired;

  /// No description provided for @invalidPort.
  ///
  /// In en, this message translates to:
  /// **'Invalid port (1-65535)'**
  String get invalidPort;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error: {error}'**
  String connectionError(String error);

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About DocFlow'**
  String get aboutTitle;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String appVersion(String version);

  /// No description provided for @supportLabel.
  ///
  /// In en, this message translates to:
  /// **'Suggestions or Bugs (GitHub)'**
  String get supportLabel;

  /// No description provided for @settingsMenu.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsMenu;
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
      'that was used.');
}
