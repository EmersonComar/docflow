class PostgresCredentials {
  final String host;
  final int port;
  final String database;
  final String username;
  final String password;
  final bool sslEnabled;

  /// Certificado (PEM) confiado explicitamente para esta conexão, usado
  /// quando o servidor apresenta um certificado autoassinado (não emitido
  /// por uma CA do trust store do sistema). Quando presente, a conexão
  /// confia *apenas* neste certificado — não nas CAs públicas — o que é
  /// mais restritivo (e mais seguro) do que aceitar qualquer certificado.
  ///
  /// `null` significa "usar o trust store padrão do sistema" (caso normal
  /// de um certificado emitido por uma CA real).
  final String? caCertificatePem;

  const PostgresCredentials({
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    required this.password,
    this.sslEnabled = false,
    this.caCertificatePem,
  });

  factory PostgresCredentials.fromJson(Map<String, dynamic> json) {
    return PostgresCredentials(
      host: json['host'] as String? ?? '',
      port: json['port'] as int? ?? 5432,
      database: json['database'] as String? ?? '',
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      sslEnabled: json['ssl_enabled'] as bool? ?? false,
      caCertificatePem: json['ca_certificate_pem'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'host': host,
      'port': port,
      'database': database,
      'username': username,
      'password': password,
      'ssl_enabled': sslEnabled,
      if (caCertificatePem != null) 'ca_certificate_pem': caCertificatePem,
    };
  }

  PostgresCredentials copyWith({
    String? host,
    int? port,
    String? database,
    String? username,
    String? password,
    bool? sslEnabled,
    String? caCertificatePem,
    bool clearCaCertificatePem = false,
  }) {
    return PostgresCredentials(
      host: host ?? this.host,
      port: port ?? this.port,
      database: database ?? this.database,
      username: username ?? this.username,
      password: password ?? this.password,
      sslEnabled: sslEnabled ?? this.sslEnabled,
      caCertificatePem: clearCaCertificatePem
          ? null
          : (caCertificatePem ?? this.caCertificatePem),
    );
  }

  bool get isEmpty =>
      host.isEmpty ||
      port == 0 ||
      database.isEmpty ||
      username.isEmpty ||
      password.isEmpty;

  bool get isValid =>
      host.isNotEmpty &&
      port > 0 &&
      database.isNotEmpty &&
      username.isNotEmpty &&
      password.isNotEmpty;
}
