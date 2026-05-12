import 'package:flutter_test/flutter_test.dart';
import 'package:docflow/domain/entities/template.dart';

void main() {
  group('Template', () {
    group('Construtor', () {
      test('cria template com valores padrão corretos', () {
        const template = Template(
          titulo: 'Meu Template',
          conteudo: 'Conteúdo',
          tags: [],
        );

        expect(template.id, isNull);
        expect(template.titulo, equals('Meu Template'));
        expect(template.conteudo, equals('Conteúdo'));
        expect(template.tags, isEmpty);
        expect(template.markdownEnabled, isTrue);
        expect(template.snippetsEnabled, isTrue);
      });

      test('cria template com todos os campos preenchidos', () {
        const template = Template(
          id: 42,
          titulo: 'Template Completo',
          conteudo: 'Conteúdo completo',
          tags: ['tag1', 'tag2'],
          markdownEnabled: false,
          snippetsEnabled: false,
        );

        expect(template.id, equals(42));
        expect(template.titulo, equals('Template Completo'));
        expect(template.conteudo, equals('Conteúdo completo'));
        expect(template.tags, equals(['tag1', 'tag2']));
        expect(template.markdownEnabled, isFalse);
        expect(template.snippetsEnabled, isFalse);
      });
    });

    group('copyWith', () {
      const original = Template(
        id: 1,
        titulo: 'Original',
        conteudo: 'Conteúdo original',
        tags: ['a'],
        markdownEnabled: true,
        snippetsEnabled: true,
      );

      test('retorna um template igual quando nenhum campo é alterado', () {
        final copy = original.copyWith();

        expect(copy.id, equals(original.id));
        expect(copy.titulo, equals(original.titulo));
        expect(copy.conteudo, equals(original.conteudo));
        expect(copy.tags, equals(original.tags));
        expect(copy.markdownEnabled, equals(original.markdownEnabled));
        expect(copy.snippetsEnabled, equals(original.snippetsEnabled));
      });

      test('altera somente o id', () {
        final copy = original.copyWith(id: 99);

        expect(copy.id, equals(99));
        expect(copy.titulo, equals(original.titulo));
        expect(copy.conteudo, equals(original.conteudo));
      });

      test('altera somente o titulo', () {
        final copy = original.copyWith(titulo: 'Novo Título');

        expect(copy.titulo, equals('Novo Título'));
        expect(copy.conteudo, equals(original.conteudo));
      });

      test('altera múltiplos campos simultaneamente', () {
        final copy = original.copyWith(
          titulo: 'Novo',
          markdownEnabled: false,
          tags: ['x', 'y'],
        );

        expect(copy.titulo, equals('Novo'));
        expect(copy.markdownEnabled, isFalse);
        expect(copy.tags, equals(['x', 'y']));
        expect(copy.snippetsEnabled, equals(original.snippetsEnabled));
      });
    });

    group('Igualdade (==) e hashCode', () {
      const t1 = Template(
        id: 1,
        titulo: 'T',
        conteudo: 'C',
        tags: [],
        markdownEnabled: true,
        snippetsEnabled: true,
      );

      test('templates com mesmos campos são iguais', () {
        const t2 = Template(
          id: 1,
          titulo: 'T',
          conteudo: 'C',
          tags: [],
          markdownEnabled: true,
          snippetsEnabled: true,
        );

        expect(t1, equals(t2));
      });

      test('templates idênticos têm o mesmo hashCode', () {
        const t2 = Template(
          id: 1,
          titulo: 'T',
          conteudo: 'C',
          tags: [],
          markdownEnabled: true,
          snippetsEnabled: true,
        );

        expect(t1.hashCode, equals(t2.hashCode));
      });

      test('templates com ids diferentes não são iguais', () {
        final t2 = t1.copyWith(id: 2);

        expect(t1, isNot(equals(t2)));
      });

      test('templates com titulos diferentes não são iguais', () {
        final t2 = t1.copyWith(titulo: 'Outro');

        expect(t1, isNot(equals(t2)));
      });

      test('templates com markdownEnabled diferentes não são iguais', () {
        final t2 = t1.copyWith(markdownEnabled: false);

        expect(t1, isNot(equals(t2)));
      });

      test('um template é igual a si mesmo (identical)', () {
        expect(t1, equals(t1));
      });

      test('um template não é igual a um objeto de outro tipo', () {
        // ignore: unrelated_type_equality_checks
        expect(t1 == 'string', isFalse);
      });
    });
  });
}
