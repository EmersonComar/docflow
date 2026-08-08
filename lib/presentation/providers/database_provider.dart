import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../core/services/app_config_service.dart';
import '../../data/datasources/local_database.dart';
import '../../data/repositories/template_repository_impl.dart';
import 'changelog_provider.dart';
import 'locale_provider.dart';
import 'template_provider.dart';
import 'theme_notifier.dart';
import '../../data/models/postgres_credentials.dart';
import '../../data/datasources/drivers/driver_factory.dart';

enum DatabaseStatus { unset, loading, ready, error }


class DatabaseProvider extends ChangeNotifier {
  final AppConfigService _configService;

  DatabaseStatus _status = DatabaseStatus.unset;
  String? _error;
  String? _currentDbPath;
  String? _currentPostgresHost;

  LocalDatabase? _database;
  ThemeNotifier? _themeNotifier;
  LocaleProvider? _localeProvider;
  ChangelogProvider? _changelogProvider;
  TemplateProvider? _templateProvider;

  DatabaseProvider(this._configService);


  DatabaseStatus get status => _status;
  String? get error => _error;

  String? get currentDbName {
    if (_currentDbPath != null) {
      return File(_currentDbPath!).uri.pathSegments.last;
    }
    if (_currentPostgresHost != null) {
      return 'postgres@$_currentPostgresHost';
    }
    return null;
  }

  ThemeNotifier? get themeNotifier => _themeNotifier;
  LocaleProvider? get localeProvider => _localeProvider;
  ChangelogProvider? get changelogProvider => _changelogProvider;
  TemplateProvider? get templateProvider => _templateProvider;


  Future<void> tryAutoOpen() async {
    // Try Postgres first
    final postgresCreds = await _configService.loadPostgresCredentials();
    if (postgresCreds != null) {
      await openPostgresDatabase(postgresCreds);
      return;
    }

    // Fallback to SQLite
    final savedPath = await _configService.loadLastDbPath();
    if (savedPath == null || !File(savedPath).existsSync()) {
      _status = DatabaseStatus.unset;
      notifyListeners();
      return;
    }
    await _open(savedPath, seedIfNew: false);
  }

  Future<void> createDatabase(String path) async {
    await _open(path, seedIfNew: true);
  }
  Future<void> openDatabase(String path) async {
    await _open(path, seedIfNew: false);
  }

  Future<void> openPostgresDatabase(PostgresCredentials credentials) async {
    _status = DatabaseStatus.loading;
    _error = null;
    notifyListeners();

    // Clear previous SQLite path before trying Postgres
    await _configService.clearLastDbPath();
    _currentDbPath = null;

    try {
      await _database?.close();

      final driver = DriverFactory.createRemoteDriver(
        DatabaseType.postgresql,
        host: credentials.host,
        port: credentials.port,
        database: credentials.database,
        username: credentials.username,
        password: credentials.password,
        sslEnabled: credentials.sslEnabled,
        caCertificatePem: credentials.caCertificatePem,
      );

      final db = LocalDatabase.withDriver(driver);
      await db.initialize();

      await _initializeComponents(db);

      _database = db;
      _currentDbPath = null;
      _currentPostgresHost = credentials.host;

      await _configService.savePostgresCredentials(credentials);
      await _configService.clearLastDbPath();

      _status = DatabaseStatus.ready;
    } catch (e) {
      _status = DatabaseStatus.error;
      _error = e.toString();
    }

    notifyListeners();
  }

  Future<void> _open(String path, {required bool seedIfNew}) async {
    _status = DatabaseStatus.loading;
    _error = null;
    notifyListeners();

    try {
      await _database?.close();

      final db = LocalDatabase.withPath(path);
      await db.initialize();

      await _initializeComponents(db, seedTemplates: seedIfNew);

      _database = db;
      _currentDbPath = path;
      _currentPostgresHost = null;

      await _configService.saveLastDbPath(path);
      await _configService.clearPostgresCredentials();

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

  Future<void> disconnect() async {
    await _database?.close();
    _database = null;
    _currentDbPath = null;
    _currentPostgresHost = null;
    _status = DatabaseStatus.unset;
    _error = null;

    // Clear saved configs to avoid auto-reopening the same database
    await _configService.clearLastDbPath();
    await _configService.clearPostgresCredentials();

    notifyListeners();
  }

  Future<void> _initializeComponents(LocalDatabase db,
      {bool seedTemplates = false}) async {
    final themeNotifier = ThemeNotifier(db);
    await themeNotifier.loadTheme();

    final localeProvider = LocaleProvider(db);
    final changelogProvider = ChangelogProvider(db)..load();

    final repository = seedTemplates
        ? TemplateRepositoryImpl(db)
        : TemplateRepositoryImpl.preInitialized(db);

    final templateProvider = TemplateProvider(repository);

    _themeNotifier = themeNotifier;
    _localeProvider = localeProvider;
    _changelogProvider = changelogProvider;
    _templateProvider = templateProvider;
  }
}
