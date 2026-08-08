import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:docflow/data/datasources/drivers/postgres_driver.dart';

// Certificado autoassinado real (gerado com openssl só para este teste) —
// não corresponde a nenhum servidor, serve apenas para validar que
// buildSecurityContext aceita um PEM bem formado.
const _validPem = '''
-----BEGIN CERTIFICATE-----
MIIDFzCCAf+gAwIBAgIUNTOQAp71VknOUxKmtLTfuvwugiswDQYJKoZIhvcNAQEL
BQAwGzEZMBcGA1UEAwwQdGVzdC5leGFtcGxlLmNvbTAeFw0yNjA4MDcxMzQ4MTZa
Fw0zNjA4MDQxMzQ4MTZaMBsxGTAXBgNVBAMMEHRlc3QuZXhhbXBsZS5jb20wggEi
MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDCMQTuDdSXzeF1kn4RZchnSmRG
r0kcXuhQ3R2o7bYwlmqV2jNFK5j45EgyxrF668Zv36JsDC+vTMaZsV9r/0BWqvBF
5cos7+qsIm3aOEbwFzFdGNTl5bbKQebfl//xLtKZHfO41Jvs7CWfkwnaMJuIdHqu
W8bEKDmP7yMGJkyWAnLEOhY1hQDxbLz8JG823PFJagCL8mOmLVfnDWEpmyN5gshn
plVGCz+s6gQLaErZ+W2D0Qv5Xu8UwE1vZ+zYQv7HuCaLdQZlobRY366xxywjO+lm
Q0o0YujITyVF0xC04D/96OCHDueeLdGAqKEH8ipIPduoX7CU3o8Z6ZcpW8SDAgMB
AAGjUzBRMB0GA1UdDgQWBBSIzWFOfNwAESSCegIp8fG7fyyX3jAfBgNVHSMEGDAW
gBSIzWFOfNwAESSCegIp8fG7fyyX3jAPBgNVHRMBAf8EBTADAQH/MA0GCSqGSIb3
DQEBCwUAA4IBAQANyo//ec3sGpLGlYq06nD/u4d8CiZsba3YecAE3Y/Yte61qBY+
vpbgCDhlKHoM4wIxdNhxJcBMMWHA6m9zsn94ruzgt9JgQ2p3EoGRBlQPgGgwSizW
UPxOIwMNDkYEa0kdvKyXsWpahb+9JWRIe8FAmS4mMXsB8Daez37ay+t0Z1jHL8ok
CEh+fjifm/Kz2IJ8j6QaxI5IM37WjZ631L/06zb92/flmaasVuCdqZhU0oFtPKat
jioVUmzgt8EA0QvPJkLbmBmSFbJXxSzNHRxc+8YrpgE54kq7NXJqNIAS8orLaJ/s
hx0JtLUWGwRhxoGiYWG9QoUAmIfQRwoTIzda
-----END CERTIFICATE-----
''';

void main() {
  group('buildSecurityContext', () {
    test('retorna null quando caCertificatePem é null', () {
      expect(buildSecurityContext(null), isNull);
    });

    test('retorna null quando caCertificatePem é string vazia ou só espaços', () {
      expect(buildSecurityContext(''), isNull);
      expect(buildSecurityContext('   \n  '), isNull);
    });

    test('retorna um SecurityContext quando caCertificatePem é um PEM válido', () {
      final context = buildSecurityContext(_validPem);

      expect(context, isNotNull);
      expect(context, isA<SecurityContext>());
    });

    test('lança erro quando caCertificatePem não é um PEM válido', () {
      expect(
        () => buildSecurityContext('isto não é um certificado'),
        throwsA(anything),
      );
    });
  });
}
