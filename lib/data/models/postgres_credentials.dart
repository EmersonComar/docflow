class PostgresCredentials {
  final String host;
  final int port;
  final String database;
  final String username;
  final String password;
  final bool sslEnabled;

  const PostgresCredentials({
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    required this.password,
    this.sslEnabled = false,
  });

  factory PostgresCredentials.fromJson(Map<String, dynamic> json) {
    return PostgresCredentials(
      host: json['host'] as String? ?? '',
      port: json['port'] as int? ?? 5432,
      database: json['database'] as String? ?? '',
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      sslEnabled: json['ssl_enabled'] as bool? ?? false,
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
    };
  }

  PostgresCredentials copyWith({
    String? host,
    int? port,
    String? database,
    String? username,
    String? password,
    bool? sslEnabled,
  }) {
    return PostgresCredentials(
      host: host ?? this.host,
      port: port ?? this.port,
      database: database ?? this.database,
      username: username ?? this.username,
      password: password ?? this.password,
      sslEnabled: sslEnabled ?? this.sslEnabled,
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
