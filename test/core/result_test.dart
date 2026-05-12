import 'package:flutter_test/flutter_test.dart';
import 'package:docflow/core/utils/result.dart';
import 'package:docflow/core/errors/failures.dart';

void main() {
  group('Result', () {
    group('Result.success', () {
      test('isSuccess é true e isFailure é false', () {
        final result = Result.success(42);

        expect(result.isSuccess, isTrue);
        expect(result.isFailure, isFalse);
      });

      test('data retorna o valor correto', () {
        final result = Result.success('hello');

        expect(result.data, equals('hello'));
      });

      test('acessar failure em um success lança StateError', () {
        final result = Result.success(1);

        expect(() => result.failure, throwsStateError);
      });
    });

    group('Result.failure', () {
      test('isFailure é true e isSuccess é false', () {
        final result = Result<int>.failure(
          const DatabaseFailure('erro'),
        );

        expect(result.isFailure, isTrue);
        expect(result.isSuccess, isFalse);
      });

      test('failure retorna o objeto de falha correto', () {
        const failure = ValidationFailure('campoObrigatorio');
        final result = Result<String>.failure(failure);

        expect(result.failure, equals(failure));
      });

      test('acessar data em um failure lança StateError', () {
        final result = Result<int>.failure(const DatabaseFailure('erro'));

        expect(() => result.data, throwsStateError);
      });
    });

    group('getOrElse', () {
      test('retorna o dado quando é success', () {
        final result = Result.success(10);

        expect(result.getOrElse(() => 0), equals(10));
      });

      test('retorna o valor padrão quando é failure', () {
        final result = Result<int>.failure(const DatabaseFailure('erro'));

        expect(result.getOrElse(() => 99), equals(99));
      });
    });

    group('map', () {
      test('transforma o dado em success', () {
        final result = Result.success(5);
        final mapped = result.map((v) => v * 2);

        expect(mapped.isSuccess, isTrue);
        expect(mapped.data, equals(10));
      });

      test('propaga failure sem transformar', () {
        const failure = DatabaseFailure('erro');
        final result = Result<int>.failure(failure);
        final mapped = result.map((v) => v * 2);

        expect(mapped.isFailure, isTrue);
        expect(mapped.failure, equals(failure));
      });
    });

    group('flatMap', () {
      test('encadeia operação assíncrona em success', () async {
        final result = Result.success(3);
        final chained = await result.flatMap(
          (v) async => Result.success(v + 1),
        );

        expect(chained.isSuccess, isTrue);
        expect(chained.data, equals(4));
      });

      test('não executa a transformação em failure', () async {
        const failure = DatabaseFailure('erro');
        final result = Result<int>.failure(failure);
        bool called = false;

        final chained = await result.flatMap((v) async {
          called = true;
          return Result.success(v);
        });

        expect(called, isFalse);
        expect(chained.isFailure, isTrue);
        expect(chained.failure, equals(failure));
      });
    });

    group('Result<void>', () {
      test('success com null é válido', () {
        final result = Result.success(null);

        expect(result.isSuccess, isTrue);
        expect(result.data, isNull);
      });
    });
  });
}
