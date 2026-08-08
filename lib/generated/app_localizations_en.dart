// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'DocFlow';

  @override
  String get newsTitle => 'What\'s New';

  @override
  String get filters => 'Filters';

  @override
  String get search => 'Search';

  @override
  String get tags => 'Tags';

  @override
  String get noTagsFound => 'No tags found.';

  @override
  String get searchTagsHint => 'Filter tags...';

  @override
  String get sortLabel => 'Sort by';

  @override
  String get sortRecentlyUpdated => 'Recently edited';

  @override
  String get sortRecentlyCreated => 'Recently created';

  @override
  String get sortTitleAsc => 'Title (A-Z)';

  @override
  String get pinTemplateTooltip => 'Pin';

  @override
  String get unpinTemplateTooltip => 'Unpin';

  @override
  String get copyCodeSnack => 'Code copied!';

  @override
  String get copyCodeTooltip => 'Copy code';

  @override
  String get editTemplate => 'Edit Template';

  @override
  String get newTemplate => 'New Template';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get titleLabel => 'Title';

  @override
  String get contentLabel => 'Content';

  @override
  String get pleaseInsertTitle => 'Please enter a title';

  @override
  String get pleaseInsertContent => 'Please enter the content';

  @override
  String get tagsLabel => 'Tags (comma separated)';

  @override
  String get importMarkdown => 'Import markdown';

  @override
  String get importMarkdownError =>
      'Failed to read the markdown file. Please make sure it is a valid UTF-8 file.';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get noTemplatesFound => 'No templates found.';

  @override
  String get confirmDeleteTitle => 'Confirm Deletion';

  @override
  String confirmDeleteContent(String title) {
    return 'Are you sure you want to delete the template \"$title\"?';
  }

  @override
  String get cancelButton => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get contentCopied => 'Content copied!';

  @override
  String get copy => 'Copy';

  @override
  String get changeTheme => 'Change Theme';

  @override
  String get newTemplateFab => 'New Template';

  @override
  String unexpectedError(String error) {
    return 'Unexpected error: $error';
  }

  @override
  String loadMoreFailed(String error) {
    return 'Failed to load more templates: $error';
  }

  @override
  String databaseInitializationFailed(String error) {
    return 'Failed to initialize database: $error';
  }

  @override
  String createTemplateFailed(String error) {
    return 'Failed to create template: $error';
  }

  @override
  String get templateIdCannotBeNull => 'Template ID cannot be null';

  @override
  String updateTemplateFailed(String error) {
    return 'Failed to update template: $error';
  }

  @override
  String deleteTemplateFailed(String error) {
    return 'Failed to delete template: $error';
  }

  @override
  String loadTemplatesFailed(String error) {
    return 'Failed to load templates: $error';
  }

  @override
  String loadTagsFailed(String error) {
    return 'Failed to load tags: $error';
  }

  @override
  String get unknownError => 'An unknown error occurred';

  @override
  String get fillVariablesTitle => 'Fill Variables';

  @override
  String get confirmCopy => 'Copy';

  @override
  String get changeLanguage => 'Language';

  @override
  String get enableMarkdown => 'Enable Markdown';

  @override
  String get enableSnippets => 'Enable Snippets';

  @override
  String get templateSettings => 'Settings';

  @override
  String get markdownPreview => 'Preview';

  @override
  String get plainTextPreview => 'Plain text';

  @override
  String get welcomeTitle => 'Welcome to DocFlow!';

  @override
  String get welcomeSubtitle =>
      'All your templates in one place.\nChoose where to store your data file.';

  @override
  String get createNewDatabase => 'Create new file';

  @override
  String get openExistingDatabase => 'Open existing file';

  @override
  String get openAnotherFile => 'Open another file';

  @override
  String currentFile(String name) {
    return 'File: $name';
  }

  @override
  String get databaseNotFound => 'File not found. Please choose another.';

  @override
  String get selectSaveLocation => 'Choose save location';

  @override
  String get selectDatabaseFile => 'Select database file';

  @override
  String get invalidDatabaseFile =>
      'The selected file is not a valid database.';

  @override
  String get postgresConnectionTitle => 'PostgreSQL Connection';

  @override
  String get postgresConnectionSubtitle =>
      'Connect to an external PostgreSQL database';

  @override
  String get serverIpLabel => 'Server IP / Hostname';

  @override
  String get portLabel => 'Port';

  @override
  String get databaseLabel => 'Database';

  @override
  String get usernameLabel => 'Username';

  @override
  String get passwordLabel => 'Password';

  @override
  String get connectButton => 'Connect';

  @override
  String get connecting => 'Connecting...';

  @override
  String get allFieldsRequired => 'All fields are required';

  @override
  String get invalidPort => 'Invalid port (1-65535)';

  @override
  String connectionError(String error) {
    return 'Connection error: $error';
  }

  @override
  String get aboutTitle => 'About DocFlow';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get supportLabel => 'Suggestions or Bugs (GitHub)';

  @override
  String get settingsMenu => 'Settings';

  @override
  String get sslEnabled => 'Enable SSL';

  @override
  String get selfSignedCertToggle => 'Self-signed certificate';

  @override
  String get selfSignedCertHint =>
      'Needed when the server uses a certificate that wasn\'t issued by a public certificate authority';

  @override
  String get selectCertificateButton => 'Select certificate (.pem/.crt)';

  @override
  String certificateSelectedLabel(String fileName) {
    return 'Selected certificate: $fileName';
  }

  @override
  String get removeCertificateTooltip => 'Remove certificate';

  @override
  String get certificateRequiredError =>
      'Select the server\'s certificate file';

  @override
  String get certificateReadError => 'Could not read the selected certificate.';

  @override
  String get certificateInvalidFormat =>
      'The selected file doesn\'t look like a valid PEM certificate.';
}
