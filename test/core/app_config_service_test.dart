import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:docflow/core/services/app_config_service.dart';
import 'package:docflow/core/services/encryption_service.dart';
import 'package:docflow/core/services/keyring_key_provider.dart';

void main() {
  late Directory tempDir;
  late AppConfigService service;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('docflow_config_test_');
    final encryption = await EncryptionService.create(
      keyProvider: InMemoryKeyProvider(),
    );
    service = AppConfigService(configDir: tempDir, encryptionService: encryption);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('AppConfigService', () {
    test('loadLastDbPath retorna null quando o arquivo de config não existe', () async {
      final path = await service.loadLastDbPath();

      expect(path, isNull);
    });

    test('saveLastDbPath persiste e loadLastDbPath recupera o caminho', () async {
      const expectedPath = '/home/user/documentos/templates.db';

      await service.saveLastDbPath(expectedPath);
      final loaded = await service.loadLastDbPath();

      expect(loaded, equals(expectedPath));
    });

    test('loadLastDbPath retorna null após clear()', () async {
      await service.saveLastDbPath('/algum/caminho.db');
      await service.clear();

      final path = await service.loadLastDbPath();

      expect(path, isNull);
    });

    test('saveLastDbPath grava um JSON válido no disco', () async {
      const testPath = '/home/user/meudoc.db';
      await service.saveLastDbPath(testPath);

      final file = File(p.join(tempDir.path, 'app_config.json'));
      expect(await file.exists(), isTrue);

      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      expect(json['last_db_path'], equals(testPath));
    });

    test('loadLastDbPath retorna null para string vazia salva', () async {
      final file = File(p.join(tempDir.path, 'app_config.json'));
      await file.writeAsString(jsonEncode({'last_db_path': ''}));

      final path = await service.loadLastDbPath();

      expect(path, isNull);
    });

    test('loadLastDbPath retorna null quando JSON é inválido', () async {
      final file = File(p.join(tempDir.path, 'app_config.json'));
      await file.writeAsString('este não é um json válido');

      final path = await service.loadLastDbPath();

      expect(path, isNull);
    });

    test('segundo saveLastDbPath sobrescreve o primeiro', () async {
      await service.saveLastDbPath('/caminho/original.db');
      await service.saveLastDbPath('/caminho/novo.db');

      final path = await service.loadLastDbPath();

      expect(path, equals('/caminho/novo.db'));
    });
  });
}
