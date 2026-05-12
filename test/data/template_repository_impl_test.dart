import 'package:flutter_test/flutter_test.dart';
import 'package:docflow/core/errors/failures.dart';
import 'package:docflow/data/datasources/local_database.dart';
import 'package:docflow/data/repositories/template_repository_impl.dart';

import '../helpers/test_helpers.dart';

void main() {
  late LocalDatabase database;
  late TemplateRepositoryImpl repository;

  setUpAll(() {
    initTestDatabase();
  });

  setUp(() async {
    // Inicializa o banco diretamente (sem seed de dados iniciais).
    // Isso garante que cada teste começa com um banco completamente limpo.
    database = LocalDatabase.inMemory();
    await database.initialize();
    // preInitialized pula o ensureInitialized (e o seed de dados de exemplo).
    repository = TemplateRepositoryImpl.preInitialized(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('TemplateRepositoryImpl', () {
    group('ensureInitialized', () {
      test('inicializa com sucesso', () async {
        // Usa banco próprio e repositório não-inicializado
        final db = LocalDatabase.inMemory();
        final repo = TemplateRepositoryImpl(db);

        final result = await repo.ensureInitialized();

        expect(result.isSuccess, isTrue);
        await db.close();
      });

      test('é idempotente — segunda chamada retorna success sem re-inicializar', () async {
        // repository já foi marcado como preInitialized no setUp;
        // chamar ensureInitialized retorna success imediatamente sem seed.
        final result1 = await repository.ensureInitialized();
        final result2 = await repository.ensureInitialized();

        expect(result1.isSuccess, isTrue);
        expect(result2.isSuccess, isTrue);
      });
    });

    group('create', () {
      test('cria template simples e retorna com id atribuído', () async {
        final template = makeTemplate(tags: []);

        final result = await repository.create(template);

        expect(result.isSuccess, isTrue);
        expect(result.data.id, isNotNull);
        expect(result.data.titulo, equals(template.titulo));
        expect(result.data.conteudo, equals(template.conteudo));
      });

      test('cria template com tags', () async {
        final template = makeTemplate(tags: ['dart', 'flutter']);

        final result = await repository.create(template);

        expect(result.isSuccess, isTrue);
        expect(result.data.id, isNotNull);
      });

      test('cria múltiplos templates com ids distintos', () async {
        final t1 = await repository.create(makeTemplate(titulo: 'Template A'));
        final t2 = await repository.create(makeTemplate(titulo: 'Template B'));

        expect(t1.data.id, isNotNull);
        expect(t2.data.id, isNotNull);
        expect(t1.data.id, isNot(equals(t2.data.id)));
      });
    });

    group('update', () {
      test('atualiza título e conteúdo corretamente', () async {
        final created = (await repository.create(makeTemplate())).data;

        final updated = created.copyWith(
          titulo: 'Título Atualizado',
          conteudo: 'Novo conteúdo',
        );

        final result = await repository.update(updated);

        expect(result.isSuccess, isTrue);
        expect(result.data.titulo, equals('Título Atualizado'));
        expect(result.data.conteudo, equals('Novo conteúdo'));
      });

      test('atualiza tags do template', () async {
        final created = (await repository.create(
          makeTemplate(tags: ['old']),
        )).data;

        final updated = created.copyWith(tags: ['new1', 'new2']);
        await repository.update(updated);

        final tags = (await repository.getAllTags()).data;
        expect(tags, containsAll(['new1', 'new2']));
        expect(tags, isNot(contains('old')));
      });

      test('retorna ValidationFailure quando id é null', () async {
        final template = makeTemplate(); // sem id

        final result = await repository.update(template);

        expect(result.isFailure, isTrue);
        expect(result.failure, isA<ValidationFailure>());
      });
    });

    group('delete', () {
      test('remove o template e retorna success', () async {
        final created = (await repository.create(makeTemplate())).data;

        final result = await repository.delete(created.id!);

        expect(result.isSuccess, isTrue);

        final list = await repository.getTemplates();
        expect(list.data, isEmpty);
      });

      test('faz cleanup de tags órfãs após deleção', () async {
        final created = (await repository.create(
          makeTemplate(tags: ['exclusiva']),
        )).data;

        await repository.delete(created.id!);

        final tags = (await repository.getAllTags()).data;
        expect(tags, isNot(contains('exclusiva')));
      });

      test('tags compartilhadas não são removidas quando apenas um template é deletado', () async {
        final t1 = (await repository.create(
          makeTemplate(titulo: 'T1', tags: ['compartilhada', 'so-t1']),
        )).data;
        await repository.create(
          makeTemplate(titulo: 'T2', tags: ['compartilhada']),
        );

        await repository.delete(t1.id!);

        final tags = (await repository.getAllTags()).data;
        expect(tags, contains('compartilhada'));
        expect(tags, isNot(contains('so-t1')));
      });
    });

    group('getTemplates', () {
      Future<void> seedTemplates(int count) async {
        for (int i = 1; i <= count; i++) {
          await repository.create(makeTemplate(
            titulo: 'Template $i',
            conteudo: 'Conteúdo $i',
            tags: [],
          ));
        }
      }

      test('retorna lista vazia quando não há templates', () async {
        final result = await repository.getTemplates();

        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });

      test('retorna templates existentes', () async {
        await seedTemplates(3);

        final result = await repository.getTemplates(limit: 10);

        expect(result.isSuccess, isTrue);
        expect(result.data.length, equals(3));
      });

      test('respeita o limit de paginação', () async {
        await seedTemplates(15);

        final result = await repository.getTemplates(limit: 5, offset: 0);

        expect(result.data.length, equals(5));
      });

      test('respeita o offset de paginação', () async {
        await seedTemplates(10);

        final page1 = (await repository.getTemplates(limit: 5, offset: 0)).data;
        final page2 = (await repository.getTemplates(limit: 5, offset: 5)).data;

        final page1Ids = page1.map((t) => t.id).toSet();
        final page2Ids = page2.map((t) => t.id).toSet();
        expect(page1Ids.intersection(page2Ids), isEmpty);
      });

      test('busca por searchQuery filtra por título', () async {
        await repository.create(
          makeTemplate(titulo: 'Contrato de Locação', conteudo: 'Conteúdo qualquer', tags: []),
        );
        await repository.create(
          makeTemplate(titulo: 'Ata de Reunião', conteudo: 'Outro conteúdo', tags: []),
        );

        final result = await repository.getTemplates(searchQuery: 'Contrato');

        expect(result.data.length, equals(1));
        expect(result.data.first.titulo, equals('Contrato de Locação'));
      });

      test('busca por searchQuery filtra por conteúdo', () async {
        await repository.create(
          makeTemplate(titulo: 'T1', conteudo: 'palavra-chave aqui', tags: []),
        );
        await repository.create(
          makeTemplate(titulo: 'T2', conteudo: 'conteúdo genérico', tags: []),
        );

        final result = await repository.getTemplates(searchQuery: 'palavra-chave');

        expect(result.data.length, equals(1));
        expect(result.data.first.titulo, equals('T1'));
      });

      test('filtragem por tags retorna apenas templates com a tag', () async {
        await repository.create(
          makeTemplate(titulo: 'Com Tag', tags: ['flutter']),
        );
        await repository.create(
          makeTemplate(titulo: 'Sem Tag', tags: []),
        );

        final result = await repository.getTemplates(tags: ['flutter']);

        expect(result.data.length, equals(1));
        expect(result.data.first.titulo, equals('Com Tag'));
      });

      test('filtragem por tag não existente retorna lista vazia', () async {
        await repository.create(makeTemplate(tags: ['dart']));

        final result = await repository.getTemplates(tags: ['inexistente']);

        expect(result.data, isEmpty);
      });
    });

    group('getAllTags', () {
      test('retorna lista vazia quando não há templates', () async {
        final result = await repository.getAllTags();

        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });

      test('retorna todas as tags em ordem alfabética', () async {
        await repository.create(makeTemplate(tags: ['zzz', 'aaa', 'mmm']));

        final result = await repository.getAllTags();

        expect(result.isSuccess, isTrue);
        expect(result.data, equals(['aaa', 'mmm', 'zzz']));
      });

      test('não retorna tags duplicadas de múltiplos templates', () async {
        await repository.create(makeTemplate(titulo: 'T1', tags: ['dart', 'flutter']));
        await repository.create(makeTemplate(titulo: 'T2', tags: ['dart', 'mobile']));

        final result = await repository.getAllTags();

        final dartCount = result.data.where((t) => t == 'dart').length;
        expect(dartCount, equals(1));
        expect(result.data.length, equals(3));
      });
    });
  });
}
