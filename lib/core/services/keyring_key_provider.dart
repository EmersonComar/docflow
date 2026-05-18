import 'dart:convert';
import 'dart:math';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Contrato para obter ou criar a chave mestra de criptografia.
abstract class KeyProvider {
  Future<enc.Key> getOrCreateKey();
}

/// Implementação que persiste a chave no keyring do SO via [FlutterSecureStorage].
///
/// No Linux utiliza libsecret (GNOME Keyring / KWallet).
/// Em caso de keyring indisponível, lança [KeyringUnavailableException].
class KeyringKeyProvider implements KeyProvider {
  static const _storageKey = 'docflow_master_key';

  final FlutterSecureStorage _storage;

  KeyringKeyProvider({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<enc.Key> getOrCreateKey() async {
    try {
      final existing = await _storage.read(key: _storageKey);
      if (existing != null && existing.isNotEmpty) {
        return enc.Key.fromBase64(existing);
      }

      // Gera nova chave AES-256 aleatória (32 bytes)
      final key = enc.Key.fromSecureRandom(32);
      await _storage.write(key: _storageKey, value: base64Encode(key.bytes));
      return key;
    } catch (e) {
      throw KeyringUnavailableException(
        'Não foi possível acessar o keyring do sistema operacional. '
        'Verifique se o GNOME Keyring ou KWallet está em execução. '
        'Detalhe: $e',
      );
    }
  }
}

/// Implementação exclusiva para testes — a chave existe apenas em memória.
///
/// Não depende do keyring do SO, permitindo testes isolados e determinísticos.
class InMemoryKeyProvider implements KeyProvider {
  final enc.Key _key;

  /// Cria um provedor com uma chave de 32 bytes aleatória.
  InMemoryKeyProvider() : _key = enc.Key.fromSecureRandom(32);

  /// Cria um provedor com uma chave fixa (útil para testes determinísticos).
  InMemoryKeyProvider.fromKey(this._key);

  @override
  Future<enc.Key> getOrCreateKey() async => _key;
}

/// Lançada quando o keyring do SO não está disponível.
class KeyringUnavailableException implements Exception {
  final String message;
  const KeyringUnavailableException(this.message);

  @override
  String toString() => 'KeyringUnavailableException: $message';
}

// Gerador seguro de bytes aleatórios (exposto para testes, se necessário)
List<int> generateSecureRandomBytes(int length) {
  final rng = Random.secure();
  return List<int>.generate(length, (_) => rng.nextInt(256));
}
