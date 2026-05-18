import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../data/models/postgres_credentials.dart';
import 'encryption_service.dart';
import 'keyring_key_provider.dart';

class AppConfigService {
  static const String _fileName = 'app_config.json';
  static const String _keyLastDbPath = 'last_db_path';
  static const String _keyPostgresCredentials = 'postgres_credentials';

  final Directory? _configDir;
  final EncryptionService? _encryptionService;

  /// [encryptionService] é opcional para permitir injeção em testes.
  /// Em produção, é inicializado lazily via [_getEncryption].
  AppConfigService({
    Directory? configDir,
    EncryptionService? encryptionService,
  })  : _configDir = configDir,
        _encryptionService = encryptionService;

  // Cache lazy do serviço de criptografia
  EncryptionService? _cachedEncryption;

  Future<EncryptionService?> _getEncryption() async {
    if (_encryptionService != null) return _encryptionService;
    if (_cachedEncryption != null) return _cachedEncryption;
    try {
      _cachedEncryption = await EncryptionService.create();
      return _cachedEncryption;
    } on KeyringUnavailableException catch (e) {
      // Keyring indisponível — operações de criptografia retornarão null
      // O app continuará funcional usando apenas SQLite
      // ignore: avoid_print
      print('[AppConfigService] Aviso: keyring indisponível. '
          'Credenciais PostgreSQL não poderão ser salvas/carregadas. '
          'Detalhe: $e');
      return null;
    }
  }

  Future<File> _configFile() async {
    final dir = _configDir ?? await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    return File(p.join(dir.path, _fileName));
  }

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

  Future<void> saveLastDbPath(String path) async {
    try {
      final file = await _configFile();
      final existingContent = await _readExistingConfig(file);
      existingContent[_keyLastDbPath] = path;
      await file.writeAsString(jsonEncode(existingContent));
    } catch (_) {}
  }

  Future<void> clearLastDbPath() async {
    try {
      final file = await _configFile();
      final existingContent = await _readExistingConfig(file);
      existingContent.remove(_keyLastDbPath);
      await file.writeAsString(jsonEncode(existingContent));
    } catch (_) {}
  }

  Future<PostgresCredentials?> loadPostgresCredentials() async {
    try {
      final file = await _configFile();
      if (!await file.exists()) return null;

      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final encryptedJson = json[_keyPostgresCredentials] as String?;

      if (encryptedJson == null || encryptedJson.isEmpty) return null;

      final encryption = await _getEncryption();
      if (encryption == null) return null;

      final decryptedJson = encryption.decrypt(encryptedJson);
      if (decryptedJson.isEmpty) return null;

      final credentialsMap = jsonDecode(decryptedJson) as Map<String, dynamic>;
      return PostgresCredentials.fromJson(credentialsMap);
    } catch (_) {
      return null;
    }
  }

  Future<void> savePostgresCredentials(PostgresCredentials credentials) async {
    final encryption = await _getEncryption();
    if (encryption == null) return; // keyring indisponível, não salva

    try {
      final file = await _configFile();
      final existingContent = await _readExistingConfig(file);

      final credentialsJson = jsonEncode(credentials.toJson());
      final encryptedJson = encryption.encrypt(credentialsJson);

      existingContent[_keyPostgresCredentials] = encryptedJson;
      await file.writeAsString(jsonEncode(existingContent));
    } catch (_) {}
  }

  Future<void> clearPostgresCredentials() async {
    try {
      final file = await _configFile();
      final existingContent = await _readExistingConfig(file);
      existingContent.remove(_keyPostgresCredentials);
      await file.writeAsString(jsonEncode(existingContent));
    } catch (_) {}
  }

  Future<Map<String, dynamic>> _readExistingConfig(File file) async {
    if (!await file.exists()) return {};
    try {
      final content = await file.readAsString();
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> clear() async {
    try {
      final file = await _configFile();
      if (await file.exists()) {
        await file.writeAsString(jsonEncode({_keyLastDbPath: ''}));
      }
    } catch (_) {}
  }
}
