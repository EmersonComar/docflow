class PostgresCredentials {
  final String host;
  final int port;
  final String database;
  final String username;
  final String password;

  const PostgresCredentials({
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    required this.password,
  });

  factory PostgresCredentials.fromJson(Map<String, dynamic> json) {
    return PostgresCredentials(
      host: json['host'] as String? ?? '',
      port: json['port'] as int? ?? 5432,
      database: json['database'] as String? ?? '',
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'host': host,
      'port': port,
      'database': database,
      'username': username,
      'password': password,
    };
  }

  PostgresCredentials copyWith({
    String? host,
    int? port,
    String? database,
    String? username,
    String? password,
  }) {
    return PostgresCredentials(
      host: host ?? this.host,
      port: port ?? this.port,
      database: database ?? this.database,
      username: username ?? this.username,
      password: password ?? this.password,
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
