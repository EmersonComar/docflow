import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:docflow/core/services/encryption_service.dart';
import 'package:docflow/core/services/keyring_key_provider.dart';

void main() {
  late EncryptionService service;

  setUp(() async {
    service = await EncryptionService.create(
      keyProvider: InMemoryKeyProvider(),
    );
  });

  test('encrypt produz valor diferente do plaintext', () {
    const original = 'test-string-123';
    final encrypted = service.encrypt(original);
    expect(encrypted, isNot(equals(original)));
  });

  test('decrypt(encrypt(x)) == x', () {
    const original = 'test-string-123';
    final encrypted = service.encrypt(original);
    final decrypted = service.decrypt(encrypted);
    expect(decrypted, equals(original));
  });

  test('IV é diferente a cada encrypt (não-determinístico)', () {
    const original = 'mesmo-plaintext';
    final enc1 = service.encrypt(original);
    final enc2 = service.encrypt(original);
    expect(enc1, isNot(equals(enc2)));
  });

  test('decrypt retorna string vazia para dado corrompido', () {
    final result = service.decrypt('dados-invalidos-!!!');
    expect(result, equals(''));
  });

  test('decrypt retorna string vazia para ciphertext de outra chave', () async {
    final otherService = await EncryptionService.create(
      keyProvider: InMemoryKeyProvider(),
    );
    final encryptedByOther = otherService.encrypt('segredo');
    final result = service.decrypt(encryptedByOther);
    expect(result, equals(''));
  });

  test('encrypt/decrypt preserva strings longas e com caracteres especiais', () {
    const original =
        'host=localhost port=5432 user=adm@ção password=P@\$\$w0rd! dbname=mydb';
    final encrypted = service.encrypt(original);
    final decrypted = service.decrypt(encrypted);
    expect(decrypted, equals(original));
  });

  test('encrypt produz ciphertext no formato AES-GCM (1 byte de versão + nonce de 12 bytes)', () {
    final encrypted = service.encrypt('segredo');
    final bytes = base64Decode(encrypted);

    expect(bytes[0], equals(0x02));
    expect(bytes.length, greaterThan(1 + 12));
  });

  test('decrypt retorna string vazia para ciphertext no formato legado (AES-CBC, sem marcador)', () {
    final rng = Random.secure();
    final legacyBlob = Uint8List.fromList(
      List<int>.generate(16 + 32, (_) => rng.nextInt(256)),
    );
    final legacyCiphertext = base64Encode(legacyBlob);

    final result = service.decrypt(legacyCiphertext);

    expect(result, equals(''));
  });
}
