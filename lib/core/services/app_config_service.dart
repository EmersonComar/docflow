import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Persists application-level configuration (independent of any database file).
///
/// Configuration is stored in `<applicationSupportDir>/app_config.json`.
/// On Linux this resolves to `~/.local/share/docflow/app_config.json`.
///
/// An optional [configDir] can be injected for testing purposes.
class AppConfigService {
  static const String _fileName = 'app_config.json';
  static const String _keyLastDbPath = 'last_db_path';

  final Directory? _configDir;

  /// Creates an [AppConfigService].
  /// In production, leave [configDir] null to use the system directory.
  /// In tests, pass a temp [Directory] to avoid writing to the real filesystem.
  AppConfigService({Directory? configDir}) : _configDir = configDir;

  /// Returns the path to the configuration file.
  Future<File> _configFile() async {
    final dir = _configDir ?? await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    return File(p.join(dir.path, _fileName));
  }

  /// Returns the last used database path, or `null` if no config exists.
  Future<String?> loadLastDbPath() async {
    try {
      final file = await _configFile();
      if (!await file.exists()) return null;

      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final path = json[_keyLastDbPath] as String?;
      return (path != null && path.isNotEmpty) ? path : null;
    } catch (_) {
      return null;
    }
  }

  /// Persists [path] as the last used database path.
  Future<void> saveLastDbPath(String path) async {
    try {
      final file = await _configFile();
      final json = {_keyLastDbPath: path};
      await file.writeAsString(jsonEncode(json));
    } catch (_) {
      // Config persistence is best-effort; ignore errors.
    }
  }

  /// Removes the stored database path (triggers WelcomeScreen on next launch).
  Future<void> clear() async {
    try {
      final file = await _configFile();
      if (await file.exists()) {
        await file.writeAsString(jsonEncode({_keyLastDbPath: ''}));
      }
    } catch (_) {}
  }
}
