import 'dart:io';

import 'package:docflow/data/datasources/drivers/sqlite_drift_driver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    initTestDatabase();
  });

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('docflow_migration_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'abre sem erro um banco cujas colunas já existem mas o user_version está desatualizado',
    () async {
      final path = '${tempDir.path}/templates.db';

      final legacyDb = await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 3,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE templates (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                titulo TEXT NOT NULL,
                conteudo TEXT NOT NULL,
                markdown_enabled INTEGER NOT NULL DEFAULT 1,
                snippets_enabled INTEGER NOT NULL DEFAULT 1,
                updated_at TEXT,
                pinned INTEGER NOT NULL DEFAULT 0
              )
            ''');
            await db.execute('''
              CREATE TABLE tags (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL UNIQUE
              )
            ''');
            await db.execute('''
              CREATE TABLE template_tags (
                template_id INTEGER NOT NULL,
                tag_id INTEGER NOT NULL,
                PRIMARY KEY (template_id, tag_id)
              )
            ''');
          },
        ),
      );
      await legacyDb.close();

      final driver = SqliteDriftDriver.withPath(path);

      await driver.initialize();

      final id = await driver.insertTemplate(
        titulo: 'Teste',
        conteudo: 'Conteúdo',
        markdownEnabled: true,
        snippetsEnabled: true,
      );
      expect(id, greaterThan(0));

      await driver.close();
    },
  );
}
