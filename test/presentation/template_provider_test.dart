import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:docflow/core/errors/failures.dart';
import 'package:docflow/core/utils/result.dart';
import 'package:docflow/domain/entities/template.dart';
import 'package:docflow/domain/entities/template_sort_option.dart';
import 'package:docflow/domain/repositories/template_repository.dart';
import 'package:docflow/presentation/providers/template_provider.dart';

import 'template_provider_test.mocks.dart';

@GenerateMocks([TemplateRepository])
void main() {
  late MockTemplateRepository mockRepository;
  late TemplateProvider provider;

  // Templates de apoio
  final tTemplate = Template(
    id: 1,
    titulo: 'Template Teste',
    conteudo: 'Conteúdo',
    tags: const ['tag1'],
  );

  final tTemplateList = List.generate(
    3,
    (i) => Template(
      id: i + 1,
      titulo: 'Template ${i + 1}',
      conteudo: 'Conteúdo ${i + 1}',
      tags: const [],
    ),
  );

  void stubSuccess({
    List<Template>? templates,
    List<String>? tags,
  }) {
    when(mockRepository.ensureInitialized())
        .thenAnswer((_) async => Result.success(null));
    when(mockRepository.getAllTags())
        .thenAnswer((_) async => Result.success(tags ?? ['tag1']));
    when(mockRepository.getTemplates(
      limit: anyNamed('limit'),
      offset: anyNamed('offset'),
      tags: anyNamed('tags'),
      searchQuery: anyNamed('searchQuery'),
    )).thenAnswer((_) async => Result.success(templates ?? tTemplateList));
  }

  setUp(() {
    mockRepository = MockTemplateRepository();
    provider = TemplateProvider(mockRepository);
  });

  group('TemplateProvider', () {
    group('initialize', () {
      test('define isInitialized como true após sucesso', () async {
        stubSuccess();

        await provider.initialize();

        expect(provider.isInitialized, isTrue);
        expect(provider.error, isNull);
      });

      test('carrega templates e tags após inicialização', () async {
        stubSuccess(templates: tTemplateList, tags: ['tag1']);

        await provider.initialize();

        expect(provider.templates, hasLength(3));
        expect(provider.allTags, equals(['tag1']));
      });

      test('define error e não inicializa quando ensureInitialized falha', () async {
        when(mockRepository.ensureInitialized()).thenAnswer(
          (_) async => Result.failure(const DatabaseFailure('dbFailed')),
        );

        await provider.initialize();

        expect(provider.isInitialized, isFalse);
        expect(provider.error, isNotNull);
        expect(provider.error!.$1, equals('dbFailed'));
      });

      test('é idempotente — segunda chamada não re-inicializa', () async {
        stubSuccess();

        await provider.initialize();
        await provider.initialize();

        // ensureInitialized deve ter sido chamado apenas uma vez
        verify(mockRepository.ensureInitialized()).called(1);
      });
    });

    group('refreshTemplates', () {
      test('reseta paginação e carrega templates do início', () async {
        stubSuccess(templates: tTemplateList);

        await provider.initialize();
        await provider.refreshTemplates();

        expect(provider.templates, hasLength(3));
        expect(provider.isLoading, isFalse);
      });

      test('define error quando getTemplates falha', () async {
        when(mockRepository.ensureInitialized())
            .thenAnswer((_) async => Result.success(null));
        when(mockRepository.getAllTags())
            .thenAnswer((_) async => Result.success([]));
        when(mockRepository.getTemplates(
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
          tags: anyNamed('tags'),
          searchQuery: anyNamed('searchQuery'),
        )).thenAnswer(
          (_) async => Result.failure(const DatabaseFailure('loadFailed')),
        );

        await provider.initialize();

        expect(provider.error, isNotNull);
      });

      test('hasMore é true quando retornou pageSize templates', () async {
        // pageSize padrão = 10; retornamos exatamente 10
        final tenTemplates = List.generate(
          10,
          (i) => Template(
            id: i + 1,
            titulo: 'T$i',
            conteudo: 'C',
            tags: const [],
          ),
        );
        stubSuccess(templates: tenTemplates);

        await provider.initialize();

        expect(provider.hasMore, isTrue);
      });

      test('hasMore é false quando retornou menos de pageSize templates', () async {
        stubSuccess(templates: tTemplateList); // 3 < 10

        await provider.initialize();

        expect(provider.hasMore, isFalse);
      });
    });

    group('loadMore', () {
      test('concatena novos templates à lista existente', () async {
        final page1 = List.generate(
          10,
          (i) => Template(id: i + 1, titulo: 'T${i + 1}', conteudo: 'C', tags: const []),
        );
        final page2 = [tTemplate];

        // Primeira chamada retorna 10; segunda retorna 1
        var callCount = 0;
        when(mockRepository.ensureInitialized())
            .thenAnswer((_) async => Result.success(null));
        when(mockRepository.getAllTags())
            .thenAnswer((_) async => Result.success([]));
        when(mockRepository.getTemplates(
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
          tags: anyNamed('tags'),
          searchQuery: anyNamed('searchQuery'),
        )).thenAnswer((_) async {
          callCount++;
          return Result.success(callCount == 1 ? page1 : page2);
        });

        await provider.initialize(); // carrega page1
        await provider.loadMore();  // carrega page2

        expect(provider.templates.length, equals(11));
        expect(provider.hasMore, isFalse);
      });

      test('não executa loadMore quando hasMore é false', () async {
        // Após initialize com 3 templates (< pageSize=10), hasMore = false.
        stubSuccess(templates: tTemplateList); // 3 < 10
        await provider.initialize();

        expect(provider.hasMore, isFalse);

        // Conta chamadas antes de loadMore
        final getTemplatesCallsBefore = verify(mockRepository.getTemplates(
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
          tags: anyNamed('tags'),
          searchQuery: anyNamed('searchQuery'),
        )).callCount;

        clearInteractions(mockRepository);
        await provider.loadMore(); // deve ser ignorado (hasMore = false)

        // Nenhuma chamada adicional ao getTemplates
        verifyNever(mockRepository.getTemplates(
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
          tags: anyNamed('tags'),
          searchQuery: anyNamed('searchQuery'),
        ));
        expect(getTemplatesCallsBefore, greaterThan(0));
      });
    });

    group('search', () {
      test('chama refreshTemplates com a nova query', () async {
        stubSuccess();
        await provider.initialize();

        provider.search('dart');

        // aguarda a chamada assíncrona de refreshTemplates
        await Future.delayed(Duration.zero);

        final captured = verify(mockRepository.getTemplates(
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
          tags: anyNamed('tags'),
          searchQuery: captureAnyNamed('searchQuery'),
        )).captured;

        expect(captured, contains('dart'));
      });
    });

    group('updateTag', () {
      test('atualiza a seleção de uma tag e chama refreshTemplates', () async {
        stubSuccess(tags: ['dart', 'flutter']);
        await provider.initialize();

        provider.updateTag('dart', true);
        await Future.delayed(Duration.zero);

        expect(provider.selectedTags['dart'], isTrue);
      });
    });

    group('addTemplate', () {
      test('chama create e depois refreshTemplates em caso de sucesso', () async {
        stubSuccess();
        when(mockRepository.create(any))
            .thenAnswer((_) async => Result.success(tTemplate));

        await provider.initialize();
        await provider.addTemplate(tTemplate);

        verify(mockRepository.create(any)).called(1);
      });

      test('define error quando create falha', () async {
        stubSuccess();
        when(mockRepository.create(any)).thenAnswer(
          (_) async => Result.failure(const DatabaseFailure('createFailed')),
        );

        await provider.initialize();
        await provider.addTemplate(tTemplate);

        expect(provider.error, isNotNull);
        expect(provider.error!.$1, equals('createFailed'));
      });
    });

    group('updateTemplate', () {
      test('chama update e depois refreshTemplates em caso de sucesso', () async {
        stubSuccess();
        when(mockRepository.update(any))
            .thenAnswer((_) async => Result.success(tTemplate));

        await provider.initialize();
        await provider.updateTemplate(tTemplate);

        verify(mockRepository.update(any)).called(1);
      });

      test('define error quando update falha', () async {
        stubSuccess();
        when(mockRepository.update(any)).thenAnswer(
          (_) async =>
              Result.failure(const ValidationFailure('updateFailed')),
        );

        await provider.initialize();
        await provider.updateTemplate(tTemplate);

        expect(provider.error, isNotNull);
      });
    });

    group('deleteTemplate', () {
      test('chama delete e depois refreshTemplates em caso de sucesso', () async {
        stubSuccess();
        when(mockRepository.delete(any))
            .thenAnswer((_) async => Result.success(null));

        await provider.initialize();
        await provider.deleteTemplate(1);

        verify(mockRepository.delete(1)).called(1);
      });

      test('define error quando delete falha', () async {
        stubSuccess();
        when(mockRepository.delete(any)).thenAnswer(
          (_) async => Result.failure(const DatabaseFailure('deleteFailed')),
        );

        await provider.initialize();
        await provider.deleteTemplate(1);

        expect(provider.error, isNotNull);
      });
    });

    group('setSortOption', () {
      test('atualiza sortOption e chama refreshTemplates com o novo valor', () async {
        stubSuccess();
        await provider.initialize();

        provider.setSortOption(TemplateSortOption.titleAsc);
        await Future.delayed(Duration.zero);

        expect(provider.sortOption, equals(TemplateSortOption.titleAsc));
        final captured = verify(mockRepository.getTemplates(
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
          tags: anyNamed('tags'),
          searchQuery: anyNamed('searchQuery'),
          sortOption: captureAnyNamed('sortOption'),
        )).captured;
        expect(captured.last, equals(TemplateSortOption.titleAsc));
      });

      test('não refaz o refresh se o valor escolhido já é o atual', () async {
        stubSuccess();
        await provider.initialize();
        clearInteractions(mockRepository);

        provider.setSortOption(TemplateSortOption.recentlyUpdated); // já é o padrão

        verifyNever(mockRepository.getTemplates(
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
          tags: anyNamed('tags'),
          searchQuery: anyNamed('searchQuery'),
          sortOption: anyNamed('sortOption'),
        ));
      });
    });

    group('togglePinned', () {
      test('fixa um template e recarrega a lista', () async {
        stubSuccess();
        when(mockRepository.setPinned(any, any))
            .thenAnswer((_) async => Result.success(null));
        await provider.initialize();

        await provider.togglePinned(tTemplate); // tTemplate.pinned == false

        verify(mockRepository.setPinned(tTemplate.id!, true)).called(1);
      });

      test('desafixa quando o template já está fixado', () async {
        stubSuccess();
        when(mockRepository.setPinned(any, any))
            .thenAnswer((_) async => Result.success(null));
        await provider.initialize();

        final pinned = tTemplate.copyWith(pinned: true);
        await provider.togglePinned(pinned);

        verify(mockRepository.setPinned(pinned.id!, false)).called(1);
      });

      test('define error quando setPinned falha', () async {
        stubSuccess();
        when(mockRepository.setPinned(any, any)).thenAnswer(
          (_) async => Result.failure(const DatabaseFailure('pinTemplateFailed')),
        );
        await provider.initialize();

        await provider.togglePinned(tTemplate);

        expect(provider.error, isNotNull);
        expect(provider.error!.$1, equals('pinTemplateFailed'));
      });

      test('não faz nada quando o template não tem id', () async {
        stubSuccess();
        await provider.initialize();

        final semId = tTemplate.copyWith();
        await provider.togglePinned(
          Template(titulo: semId.titulo, conteudo: semId.conteudo, tags: semId.tags),
        );

        verifyNever(mockRepository.setPinned(any, any));
      });
    });

    group('tagCounts', () {
      test('carrega a contagem de tags durante refreshTemplates', () async {
        stubSuccess();
        when(mockRepository.getTagCounts()).thenAnswer(
          (_) async => Result.success([('dart', 3), ('flutter', 1)]),
        );

        await provider.initialize();

        expect(provider.tagCounts, equals([('dart', 3), ('flutter', 1)]));
      });

      test('falha ao buscar contagem não impede o carregamento dos templates', () async {
        stubSuccess(templates: tTemplateList);
        when(mockRepository.getTagCounts()).thenThrow(Exception('boom'));

        await provider.initialize();

        expect(provider.templates, hasLength(3));
        expect(provider.tagCounts, isEmpty);
      });
    });

    group('toggleTemplateExpansion / isTemplateExpanded', () {
      test('template começa não expandido', () {
        expect(provider.isTemplateExpanded(1), isFalse);
      });

      test('após toggle, template fica expandido', () {
        provider.toggleTemplateExpansion(1);

        expect(provider.isTemplateExpanded(1), isTrue);
      });

      test('segundo toggle colapsa o template', () {
        provider.toggleTemplateExpansion(1);
        provider.toggleTemplateExpansion(1);

        expect(provider.isTemplateExpanded(1), isFalse);
      });

      test('template com id null não é expandido e toggle é ignorado', () {
        provider.toggleTemplateExpansion(null);

        expect(provider.isTemplateExpanded(null), isFalse);
      });

      test('expansão de um template não afeta outro', () {
        provider.toggleTemplateExpansion(1);

        expect(provider.isTemplateExpanded(1), isTrue);
        expect(provider.isTemplateExpanded(2), isFalse);
      });
    });
  });
}
