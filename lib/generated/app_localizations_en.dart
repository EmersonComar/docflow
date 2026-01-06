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
}
