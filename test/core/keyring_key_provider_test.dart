import 'dart:convert';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:docflow/core/services/keyring_key_provider.dart';

@GenerateNiceMocks([MockSpec<FlutterSecureStorage>()])
import 'keyring_key_provider_test.mocks.dart';

void main() {
  group('KeyringKeyProvider', () {
    late MockFlutterSecureStorage mockStorage;
    late KeyringKeyProvider provider;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      provider = KeyringKeyProvider(storage: mockStorage);
    });

    test('gera nova chave e salva no keyring quando não há chave existente',
        () async {
      when(mockStorage.read(key: anyNamed('key')))
          .thenAnswer((_) async => null);
      when(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')))
          .thenAnswer((_) async {});

      final key = await provider.getOrCreateKey();

      expect(key.bytes.length, equals(32)); 
      verify(mockStorage.write(
              key: 'docflow_master_key', value: anyNamed('value')))
          .called(1);
    });

    test('reutiliza chave existente do keyring (não gera nova)', () async {
      // Simula chave já salva
      final existingKey = enc.Key.fromSecureRandom(32);
      final existingKeyB64 = base64Encode(existingKey.bytes);

      when(mockStorage.read(key: anyNamed('key')))
          .thenAnswer((_) async => existingKeyB64);

      final key = await provider.getOrCreateKey();

      expect(key.bytes, equals(existingKey.bytes));
      verifyNever(mockStorage.write(
          key: anyNamed('key'), value: anyNamed('value')));
    });

    test('lança KeyringUnavailableException quando storage falha', () async {
      when(mockStorage.read(key: anyNamed('key')))
          .thenThrow(Exception('D-Bus connection failed'));

      expect(
        () => provider.getOrCreateKey(),
        throwsA(isA<KeyringUnavailableException>()),
      );
    });
  });

  group('InMemoryKeyProvider', () {
    test('retorna sempre a mesma chave na mesma instância', () async {
      final provider = InMemoryKeyProvider();
      final key1 = await provider.getOrCreateKey();
      final key2 = await provider.getOrCreateKey();
      expect(key1.bytes, equals(key2.bytes));
    });

    test('instâncias diferentes produzem chaves diferentes', () async {
      final provider1 = InMemoryKeyProvider();
      final provider2 = InMemoryKeyProvider();
      final key1 = await provider1.getOrCreateKey();
      final key2 = await provider2.getOrCreateKey();
      expect(key1.bytes, isNot(equals(key2.bytes)));
    });

    test('fromKey retorna a chave fornecida', () async {
      final fixedKey = enc.Key.fromSecureRandom(32);
      final provider = InMemoryKeyProvider.fromKey(fixedKey);
      final key = await provider.getOrCreateKey();
      expect(key.bytes, equals(fixedKey.bytes));
    });
  });
}
