import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'keyring_key_provider.dart';

/// Serviço de criptografia AES-CBC com IV aleatório por operação.
///
/// A chave mestra é obtida do keyring do SO via [KeyProvider] — nunca é
/// embutida no código. O IV é gerado aleatoriamente a cada [encrypt] e
/// prefixado ao ciphertext em Base64, eliminando reutilização de IV.
///
/// **Uso:**
/// ```dart
/// final service = await EncryptionService.create();
/// final encrypted = service.encrypt('segredo');
/// final original  = service.decrypt(encrypted);
/// ```
class EncryptionService {
  final enc.Encrypter _encrypter;

  EncryptionService._(this._encrypter);

  /// Cria uma instância do serviço, obtendo ou gerando a chave no keyring.
  ///
  /// Lança [KeyringUnavailableException] se o keyring não estiver acessível.
  static Future<EncryptionService> create({KeyProvider? keyProvider}) async {
    final provider = keyProvider ?? KeyringKeyProvider();
    final key = await provider.getOrCreateKey();
    return EncryptionService._(enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc)));
  }

  /// Criptografa [plaintext] usando AES-CBC com IV aleatório de 16 bytes.
  ///
  /// Formato do resultado (Base64): `<IV_16_bytes><ciphertext>`
  String encrypt(String plaintext) {
    final iv = _randomIv();
    final encrypted = _encrypter.encrypt(plaintext, iv: iv);

    // Prefixa o IV ao ciphertext antes de codificar em Base64
    final combined = iv.bytes + encrypted.bytes;
    return base64Encode(combined);
  }

  /// Descriptografa um valor produzido por [encrypt].
  ///
  /// Retorna string vazia em caso de falha (dados corrompidos ou chave diferente).
  String decrypt(String encryptedBase64) {
    try {
      final combined = base64Decode(encryptedBase64);
      if (combined.length <= 16) return '';

      final ivBytes = combined.sublist(0, 16);
      final cipherBytes = combined.sublist(16);

      final iv = enc.IV(ivBytes);
      final encrypted = enc.Encrypted(cipherBytes);
      return _encrypter.decrypt(encrypted, iv: iv);
    } catch (_) {
      return '';
    }
  }

  static enc.IV _randomIv() {
    final rng = Random.secure();
    final bytes = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      bytes[i] = rng.nextInt(256);
    }
    return enc.IV(bytes);
  }
}
