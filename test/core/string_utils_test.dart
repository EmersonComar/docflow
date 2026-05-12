import 'package:flutter_test/flutter_test.dart';
import 'package:docflow/core/utils/string_utils.dart';

void main() {
  group('StringUtils', () {
    group('extractVariables', () {
      test('retorna conjunto vazio quando não há variáveis', () {
        final vars = StringUtils.extractVariables('Texto simples sem variáveis.');

        expect(vars, isEmpty);
      });

      test('extrai uma única variável simples', () {
        final vars = StringUtils.extractVariables('Olá, {{nome}}!');

        expect(vars, equals({'nome'}));
      });

      test('extrai variável com espaços ao redor', () {
        final vars = StringUtils.extractVariables('Valor: {{ preco }}');

        expect(vars, equals({'preco'}));
      });

      test('extrai múltiplas variáveis distintas', () {
        final vars = StringUtils.extractVariables(
          'Dear {{name}}, your order {{order_id}} is ready.',
        );

        expect(vars, equals({'name', 'order_id'}));
      });

      test('retorna cada variável uma única vez mesmo que repita no texto', () {
        final vars = StringUtils.extractVariables(
          '{{var}} e {{var}} novamente',
        );

        expect(vars, equals({'var'}));
        expect(vars.length, equals(1));
      });

      test('extrai variáveis com underscores e números', () {
        final vars = StringUtils.extractVariables('{{item_1}} e {{item_2}}');

        expect(vars, containsAll(['item_1', 'item_2']));
      });
    });

    group('interpolate', () {
      test('substitui uma variável pelo valor fornecido', () {
        final result = StringUtils.interpolate(
          'Olá, {{nome}}!',
          {'nome': 'Maria'},
        );

        expect(result, equals('Olá, Maria!'));
      });

      test('substitui múltiplas variáveis', () {
        final result = StringUtils.interpolate(
          '{{saudacao}}, {{nome}}!',
          {'saudacao': 'Bom dia', 'nome': 'João'},
        );

        expect(result, equals('Bom dia, João!'));
      });

      test('mantém o placeholder quando variável não é fornecida', () {
        final result = StringUtils.interpolate(
          'Valor: {{preco}}',
          {},
        );

        expect(result, equals('Valor: {{preco}}'));
      });

      test('retorna o texto original quando não há variáveis', () {
        final texto = 'Texto sem variáveis.';
        final result = StringUtils.interpolate(texto, {'chave': 'valor'});

        expect(result, equals(texto));
      });

      test('ignora variáveis do mapa que não estão no texto', () {
        final result = StringUtils.interpolate(
          'Olá, {{nome}}!',
          {'nome': 'Ana', 'sobrenome': 'Silva'},
        );

        expect(result, equals('Olá, Ana!'));
      });

      test('substitui variável com espaços ao redor do nome', () {
        final result = StringUtils.interpolate(
          'Total: {{ valor }}',
          {'valor': '100'},
        );

        expect(result, equals('Total: 100'));
      });

      test('substitui todas as ocorrências da mesma variável', () {
        final result = StringUtils.interpolate(
          '{{x}} + {{x}} = dois {{x}}',
          {'x': 'a'},
        );

        expect(result, equals('a + a = dois a'));
      });
    });
  });
}
