import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../core/services/app_config_service.dart';
import '../../data/datasources/local_database.dart';
import '../../data/repositories/template_repository_impl.dart';
import 'changelog_provider.dart';
import 'locale_provider.dart';
import 'template_provider.dart';
import 'theme_notifier.dart';

enum DatabaseStatus { unset, loading, ready, error }

/// Central provider that manages the lifecycle of the active database file.
///
/// It holds the [LocalDatabase] and all providers that depend on it:
/// [ThemeNotifier], [LocaleProvider], [ChangelogProvider], [TemplateProvider].
///
/// When the user picks a new database file, [switchDatabase] replaces all
/// sub-providers and notifies listeners so [MyApp] rebuilds the whole tree.
class DatabaseProvider extends ChangeNotifier {
  final AppConfigService _configService;

  DatabaseStatus _status = DatabaseStatus.unset;
  String? _error;
  String? _currentDbPath;

  LocalDatabase? _database;
  ThemeNotifier? _themeNotifier;
  LocaleProvider? _localeProvider;
  ChangelogProvider? _changelogProvider;
  TemplateProvider? _templateProvider;

  DatabaseProvider(this._configService);

  // ─── Getters ─────────────────────────────────────────────────────────────

  DatabaseStatus get status => _status;
  String? get error => _error;

  /// The filename (basename) of the active database, e.g. `meustemplate.db`.
  String? get currentDbName =>
      _currentDbPath != null ? File(_currentDbPath!).uri.pathSegments.last : null;

  ThemeNotifier? get themeNotifier => _themeNotifier;
  LocaleProvider? get localeProvider => _localeProvider;
  ChangelogProvider? get changelogProvider => _changelogProvider;
  TemplateProvider? get templateProvider => _templateProvider;

  // ─── Initialization ───────────────────────────────────────────────────────

  /// Called once by [main]. Reads the saved path and opens the database if
  /// the file still exists; otherwise leaves status as [DatabaseStatus.unset]
  /// so [WelcomeScreen] is shown.
  Future<void> tryAutoOpen() async {
    final savedPath = await _configService.loadLastDbPath();
    if (savedPath == null || !File(savedPath).existsSync()) {
      _status = DatabaseStatus.unset;
      notifyListeners();
      return;
    }
    await _open(savedPath, seedIfNew: false);
  }

  // ─── Public actions ───────────────────────────────────────────────────────

  /// Creates a new database at [path]. Seeds initial data since the file is new.
  Future<void> createDatabase(String path) async {
    await _open(path, seedIfNew: true);
  }

  /// Opens an existing database at [path]. No seed is applied.
  Future<void> openDatabase(String path) async {
    await _open(path, seedIfNew: false);
  }

  // ─── Internal ─────────────────────────────────────────────────────────────

  Future<void> _open(String path, {required bool seedIfNew}) async {
    _status = DatabaseStatus.loading;
    _error = null;
    notifyListeners();

    try {
      // Close the previous database gracefully.
      await _database?.close();

      final db = LocalDatabase.withPath(path);
      await db.initialize();

      final themeNotifier = ThemeNotifier(db);
      await themeNotifier.loadTheme();

      final localeProvider = LocaleProvider(db);
      final changelogProvider = ChangelogProvider(db)..load();

      final repository = seedIfNew
          ? TemplateRepositoryImpl(db)           // uses ensureInitialized → seeds data
          : TemplateRepositoryImpl.preInitialized(db); // already initialized, no seed

      final templateProvider = TemplateProvider(repository);

      _database = db;
      _themeNotifier = themeNotifier;
      _localeProvider = localeProvider;
      _changelogProvider = changelogProvider;
      _templateProvider = templateProvider;
      _currentDbPath = path;

      await _configService.saveLastDbPath(path);

      _status = DatabaseStatus.ready;
    } catch (e) {
      _status = DatabaseStatus.error;
      final errorMessage = e.toString();
      if (errorMessage.contains('file is not a database')) {
        _error = 'invalid_database_file';
      } else {
        _error = errorMessage;
      }
    }

    notifyListeners();
  }
}
