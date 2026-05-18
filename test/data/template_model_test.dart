import 'package:flutter_test/flutter_test.dart';
import 'package:docflow/data/models/template_model.dart';
import 'package:docflow/domain/entities/template.dart';

void main() {
  group('TemplateModel', () {
    group('fromMap', () {
      test('desserializa corretamente todos os campos', () {
        final map = {
          'id': 1,
          'titulo': 'Título',
          'conteudo': 'Conteúdo',
          'tags': 'dart,flutter',
          'markdown_enabled': 1,
          'snippets_enabled': 0,
        };

        final model = TemplateModel.fromMap(map);

        expect(model.id, equals(1));
        expect(model.titulo, equals('Título'));
        expect(model.conteudo, equals('Conteúdo'));
        expect(model.tags, equals(['dart', 'flutter']));
        expect(model.markdownEnabled, isTrue);
        expect(model.snippetsEnabled, isFalse);
      });

      test('tags nulo resulta em lista vazia', () {
        final map = {
          'id': 2,
          'titulo': 'Sem Tags',
          'conteudo': 'Conteúdo',
          'tags': null,
          'markdown_enabled': 1,
          'snippets_enabled': 1,
        };

        final model = TemplateModel.fromMap(map);

        expect(model.tags, isEmpty);
      });

      test('tags string vazia resulta em lista vazia', () {
        final map = {
          'id': 3,
          'titulo': 'Tags Vazias',
          'conteudo': 'Conteúdo',
          'tags': '',
          'markdown_enabled': 1,
          'snippets_enabled': 1,
        };

        final model = TemplateModel.fromMap(map);

        expect(model.tags, isEmpty);
      });

      test('tags com espaços são trimadas', () {
        final map = {
          'id': 4,
          'titulo': 'Tags com Espaços',
          'conteudo': 'Conteúdo',
          'tags': ' dart , flutter ',
          'markdown_enabled': 1,
          'snippets_enabled': 1,
        };

        final model = TemplateModel.fromMap(map);

        expect(model.tags, equals(['dart', 'flutter']));
      });

      test('markdownEnabled é false quando valor é 0', () {
        final map = {
          'id': 5,
          'titulo': 'T',
          'conteudo': 'C',
          'tags': null,
          'markdown_enabled': 0,
          'snippets_enabled': 1,
        };

        final model = TemplateModel.fromMap(map);

        expect(model.markdownEnabled, isFalse);
      });

      test('markdown_enabled nulo resulta em false', () {
        final map = {
          'id': 6,
          'titulo': 'T',
          'conteudo': 'C',
          'tags': null,
          'markdown_enabled': null,
          'snippets_enabled': null,
        };

        final model = TemplateModel.fromMap(map);

        expect(model.markdownEnabled, isFalse);
        expect(model.snippetsEnabled, isFalse);
      });
    });

    group('Suporte Multi-Banco (Booleans)', () {
      test('desserializa corretamente quando campos booleanos vêm como bool (PostgreSQL)', () {
        final map = {
          'id': 1,
          'titulo': 'Postgres',
          'conteudo': 'C',
          'tags': '',
          'markdown_enabled': true,
          'snippets_enabled': false,
        };

        final model = TemplateModel.fromMap(map);

        expect(model.markdownEnabled, isTrue);
        expect(model.snippetsEnabled, isFalse);
      });

      test('desserializa corretamente quando campos booleanos vêm como int (SQLite)', () {
        final map = {
          'id': 1,
          'titulo': 'SQLite',
          'conteudo': 'C',
          'tags': '',
          'markdown_enabled': 1,
          'snippets_enabled': 0,
        };

        final model = TemplateModel.fromMap(map);

        expect(model.markdownEnabled, isTrue);
        expect(model.snippetsEnabled, isFalse);
      });
    });

    group('toMap', () {
      test('serializa corretamente com id', () {
        const model = TemplateModel(
          id: 10,
          titulo: 'T',
          conteudo: 'C',
          tags: [],
          markdownEnabled: true,
          snippetsEnabled: false,
        );

        final map = model.toMap();

        expect(map['id'], equals(10));
        expect(map['titulo'], equals('T'));
        expect(map['conteudo'], equals('C'));
        expect(map['markdown_enabled'], equals(1));
        expect(map['snippets_enabled'], equals(0));
      });

      test('serializa sem id quando id é null (para INSERT)', () {
        const model = TemplateModel(
          titulo: 'Novo',
          conteudo: 'Conteúdo',
          tags: [],
        );

        final map = model.toMap();

        expect(map.containsKey('id'), isFalse);
      });

      test('tags não são incluídas no mapa (gerenciadas separadamente)', () {
        const model = TemplateModel(
          titulo: 'T',
          conteudo: 'C',
          tags: ['tag1'],
        );

        final map = model.toMap();

        expect(map.containsKey('tags'), isFalse);
      });
    });

    group('fromEntity', () {
      test('cria TemplateModel idêntico à entidade', () {
        const entity = Template(
          id: 7,
          titulo: 'Entidade',
          conteudo: 'Conteúdo da entidade',
          tags: ['x'],
          markdownEnabled: false,
          snippetsEnabled: true,
        );

        final model = TemplateModel.fromEntity(entity);

        expect(model.id, equals(entity.id));
        expect(model.titulo, equals(entity.titulo));
        expect(model.conteudo, equals(entity.conteudo));
        expect(model.tags, equals(entity.tags));
        expect(model.markdownEnabled, equals(entity.markdownEnabled));
        expect(model.snippetsEnabled, equals(entity.snippetsEnabled));
      });
    });

    group('toEntity', () {
      test('converte TemplateModel em Template corretamente', () {
        const model = TemplateModel(
          id: 8,
          titulo: 'Modelo',
          conteudo: 'C',
          tags: ['a', 'b'],
          markdownEnabled: true,
          snippetsEnabled: false,
        );

        final entity = model.toEntity();

        expect(entity, isA<Template>());
        expect(entity.id, equals(model.id));
        expect(entity.titulo, equals(model.titulo));
        expect(entity.tags, equals(model.tags));
        expect(entity.snippetsEnabled, isFalse);
      });
    });

    group('Round-trip fromEntity → toMap → fromMap → toEntity', () {
      test('não perde dados ao passar por todas as transformações', () {
        const original = Template(
          id: 9,
          titulo: 'Round Trip',
          conteudo: 'Conteúdo RT',
          tags: ['alpha', 'beta'],
          markdownEnabled: true,
          snippetsEnabled: true,
        );

        final model = TemplateModel.fromEntity(original);
        final map = model.toMap();
        // Tags são passadas separadamente pelo banco; simulamos aqui
        map['tags'] = original.tags.join(',');

        final recovered = TemplateModel.fromMap(map).toEntity();

        expect(recovered.id, equals(original.id));
        expect(recovered.titulo, equals(original.titulo));
        expect(recovered.conteudo, equals(original.conteudo));
        expect(recovered.tags, equals(original.tags));
        expect(recovered.markdownEnabled, equals(original.markdownEnabled));
        expect(recovered.snippetsEnabled, equals(original.snippetsEnabled));
      });
    });
  });
}
