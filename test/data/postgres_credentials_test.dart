import 'package:flutter_test/flutter_test.dart';
import 'package:docflow/data/models/postgres_credentials.dart';

void main() {
  group('PostgresCredentials', () {
    test('caCertificatePem é null por padrão', () {
      const creds = PostgresCredentials(
        host: 'localhost',
        port: 5432,
        database: 'db',
        username: 'user',
        password: 'pass',
      );

      expect(creds.caCertificatePem, isNull);
    });

    test('toJson inclui ca_certificate_pem apenas quando presente', () {
      const withoutCert = PostgresCredentials(
        host: 'localhost',
        port: 5432,
        database: 'db',
        username: 'user',
        password: 'pass',
      );
      const withCert = PostgresCredentials(
        host: 'localhost',
        port: 5432,
        database: 'db',
        username: 'user',
        password: 'pass',
        caCertificatePem: '-----BEGIN CERTIFICATE-----\nABC\n-----END CERTIFICATE-----',
      );

      expect(withoutCert.toJson().containsKey('ca_certificate_pem'), isFalse);
      expect(withCert.toJson()['ca_certificate_pem'], contains('BEGIN CERTIFICATE'));
    });

    test('fromJson reconstrói caCertificatePem quando presente', () {
      final json = {
        'host': 'localhost',
        'port': 5432,
        'database': 'db',
        'username': 'user',
        'password': 'pass',
        'ssl_enabled': true,
        'ca_certificate_pem': 'CERT-CONTENT',
      };

      final creds = PostgresCredentials.fromJson(json);

      expect(creds.caCertificatePem, equals('CERT-CONTENT'));
      expect(creds.sslEnabled, isTrue);
    });

    test('fromJson retorna caCertificatePem nulo quando ausente', () {
      final json = {
        'host': 'localhost',
        'port': 5432,
        'database': 'db',
        'username': 'user',
        'password': 'pass',
      };

      final creds = PostgresCredentials.fromJson(json);

      expect(creds.caCertificatePem, isNull);
    });

    test('copyWith preserva caCertificatePem quando não especificado', () {
      const original = PostgresCredentials(
        host: 'localhost',
        port: 5432,
        database: 'db',
        username: 'user',
        password: 'pass',
        caCertificatePem: 'CERT-CONTENT',
      );

      final updated = original.copyWith(host: 'outrohost');

      expect(updated.caCertificatePem, equals('CERT-CONTENT'));
      expect(updated.host, equals('outrohost'));
    });

    test('copyWith(clearCaCertificatePem: true) remove o certificado', () {
      const original = PostgresCredentials(
        host: 'localhost',
        port: 5432,
        database: 'db',
        username: 'user',
        password: 'pass',
        caCertificatePem: 'CERT-CONTENT',
      );

      final updated = original.copyWith(clearCaCertificatePem: true);

      expect(updated.caCertificatePem, isNull);
    });

    test('isValid não exige caCertificatePem', () {
      const creds = PostgresCredentials(
        host: 'localhost',
        port: 5432,
        database: 'db',
        username: 'user',
        password: 'pass',
        sslEnabled: true,
      );

      expect(creds.isValid, isTrue);
    });
  });
}
