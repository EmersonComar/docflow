import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:docflow/core/services/app_config_service.dart';
import 'package:docflow/presentation/providers/database_provider.dart';

import '../helpers/test_helpers.dart';

void main() {
  late Directory tempDir;
  late AppConfigService configService;

  setUpAll(() {
    initTestDatabase();
  });

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('docflow_db_provider_test_');
    configService = AppConfigService(configDir: tempDir);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  String tempDbPath(String name) => '${tempDir.path}/$name.db';

  group('DatabaseProvider', () {
    test('status inicial é unset', () {
      final provider = DatabaseProvider(configService);

      expect(provider.status, equals(DatabaseStatus.unset));
      expect(provider.themeNotifier, isNull);
      expect(provider.templateProvider, isNull);
      expect(provider.currentDbName, isNull);
    });

    group('tryAutoOpen', () {
      test('mantém status unset quando não há config salva', () async {
        final provider = DatabaseProvider(configService);

        await provider.tryAutoOpen();

        expect(provider.status, equals(DatabaseStatus.unset));
      });

      test('mantém status unset quando arquivo salvo não existe mais', () async {
        await configService.saveLastDbPath('/caminho/que/nao/existe.db');
        final provider = DatabaseProvider(configService);

        await provider.tryAutoOpen();

        expect(provider.status, equals(DatabaseStatus.unset));
      });

      test('abre automaticamente quando o arquivo existe', () async {
        // Cria um banco real no temp dir primeiro
        final path = tempDbPath('auto_open');
        final setupProvider = DatabaseProvider(configService);
        await setupProvider.createDatabase(path);

        // Agora simula novo lançamento
        final provider = DatabaseProvider(configService);
        await provider.tryAutoOpen();

        expect(provider.status, equals(DatabaseStatus.ready));
        expect(provider.currentDbName, equals('auto_open.db'));
      });
    });

    group('createDatabase', () {
      test('status fica ready após criar banco com sucesso', () async {
        final provider = DatabaseProvider(configService);
        final path = tempDbPath('novo');

        await provider.createDatabase(path);

        expect(provider.status, equals(DatabaseStatus.ready));
      });

      test('sub-providers são criados após createDatabase', () async {
        final provider = DatabaseProvider(configService);

        await provider.createDatabase(tempDbPath('sub_providers'));

        expect(provider.themeNotifier, isNotNull);
        expect(provider.localeProvider, isNotNull);
        expect(provider.changelogProvider, isNotNull);
        expect(provider.templateProvider, isNotNull);
      });

      test('currentDbName retorna o nome do arquivo', () async {
        final provider = DatabaseProvider(configService);

        await provider.createDatabase(tempDbPath('meustemplate'));

        expect(provider.currentDbName, equals('meustemplate.db'));
      });

      test('salva o caminho na config após createDatabase', () async {
        final provider = DatabaseProvider(configService);
        final path = tempDbPath('persistido');

        await provider.createDatabase(path);

        final saved = await configService.loadLastDbPath();
        expect(saved, equals(path));
      });

      test('status é error quando o caminho é inválido', () async {
        final provider = DatabaseProvider(configService);

        await provider.createDatabase('/caminho/inexistente/invalido/a/b/c.db');

        expect(provider.status, equals(DatabaseStatus.error));
        expect(provider.error, isNotNull);
      });
    });

    group('openDatabase', () {
      test('abre banco existente com sucesso', () async {
        final path = tempDbPath('existente');

        // Cria o banco primeiro
        final setupProvider = DatabaseProvider(configService);
        await setupProvider.createDatabase(path);

        // Abre com um novo provider
        final provider = DatabaseProvider(configService);
        await provider.openDatabase(path);

        expect(provider.status, equals(DatabaseStatus.ready));
      });

      test('notifica listeners quando status muda', () async {
        final provider = DatabaseProvider(configService);
        final statuses = <DatabaseStatus>[];
        provider.addListener(() => statuses.add(provider.status));

        await provider.createDatabase(tempDbPath('notificacoes'));

        expect(statuses, containsAll([
          DatabaseStatus.loading,
          DatabaseStatus.ready,
        ]));
      });

      test('permite trocar de banco (switchDatabase)', () async {
        final path1 = tempDbPath('banco1');
        final path2 = tempDbPath('banco2');

        final provider = DatabaseProvider(configService);
        await provider.createDatabase(path1);
        expect(provider.currentDbName, equals('banco1.db'));

        await provider.openDatabase(path2);
        expect(provider.currentDbName, equals('banco2.db'));
        expect(provider.status, equals(DatabaseStatus.ready));
      });

      test('define erro invalid_database_file quando abre arquivo que não é sqlite', () async {
        final path = tempDbPath('invalido.pem');
        final file = File(path);
        await file.writeAsString('Isto nao e um banco de dados sqlite. E apenas texto.');

        final provider = DatabaseProvider(configService);
        await provider.openDatabase(path);

        expect(provider.status, equals(DatabaseStatus.error));
        expect(provider.error, equals('invalid_database_file'));
      });
    });
  });
}
