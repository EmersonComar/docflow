import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'keyring_key_provider.dart';

class EncryptionService {
  final enc.Encrypter _encrypter;

  EncryptionService._(this._encrypter);

  static const int _gcmNonceLength = 12;
  static const int _formatVersionGcm = 0x02;

  static Future<EncryptionService> create({KeyProvider? keyProvider}) async {
    final provider = keyProvider ?? KeyringKeyProvider();
    final key = await provider.getOrCreateKey();
    return EncryptionService._(enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm)));
  }

  String encrypt(String plaintext) {
    final nonce = _randomNonce();
    final encrypted = _encrypter.encrypt(plaintext, iv: nonce);

    final combined = Uint8List(1 + _gcmNonceLength + encrypted.bytes.length);
    combined[0] = _formatVersionGcm;
    combined.setRange(1, 1 + _gcmNonceLength, nonce.bytes);
    combined.setRange(1 + _gcmNonceLength, combined.length, encrypted.bytes);

    return base64Encode(combined);
  }

  String decrypt(String encryptedBase64) {
    try {
      final combined = base64Decode(encryptedBase64);
      if (combined.isEmpty || combined[0] != _formatVersionGcm) return '';
      if (combined.length <= 1 + _gcmNonceLength) return '';

      final nonceBytes = combined.sublist(1, 1 + _gcmNonceLength);
      final cipherBytes = combined.sublist(1 + _gcmNonceLength);

      final nonce = enc.IV(Uint8List.fromList(nonceBytes));
      final encrypted = enc.Encrypted(Uint8List.fromList(cipherBytes));
      return _encrypter.decrypt(encrypted, iv: nonce);
    } catch (_) {
      return '';
    }
  }

  static enc.IV _randomNonce() {
    final rng = Random.secure();
    final bytes = Uint8List(_gcmNonceLength);
    for (var i = 0; i < _gcmNonceLength; i++) {
      bytes[i] = rng.nextInt(256);
    }
    return enc.IV(bytes);
  }
}
