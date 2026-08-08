import 'database_driver.dart';
import 'sqlite_drift_driver.dart';
import 'postgres_driver.dart';
import 'mysql_driver.dart';

enum DatabaseType {
  sqlite,
  postgresql,
  mysql,
  mariadb,
}

class DriverFactory {
  static DatabaseDriver createDriver(DatabaseType type) {
    switch (type) {
      case DatabaseType.sqlite:
        return SqliteDriftDriver();
      case DatabaseType.postgresql:
        throw UnsupportedError(
          'PostgreSQL requires connection credentials — use createRemoteDriver() instead.',
        );
      case DatabaseType.mysql:
      case DatabaseType.mariadb:
        return MysqlDriver();
    }
  }

  static DatabaseDriver createInMemoryDriver(DatabaseType type) {
    switch (type) {
      case DatabaseType.sqlite:
        return SqliteDriftDriver.inMemory();
      case DatabaseType.postgresql:
        return PostgresDriver.inMemory();
      case DatabaseType.mysql:
      case DatabaseType.mariadb:
        return MysqlDriver.inMemory();
    }
  }

  static DatabaseDriver createRemoteDriver(
    DatabaseType type, {
    required String host,
    required int port,
    required String database,
    required String username,
    required String password,
    bool sslEnabled = false,
    String? caCertificatePem,
  }) {
    switch (type) {
      case DatabaseType.sqlite:
        throw UnsupportedError('SQLite does not support remote connections');
      case DatabaseType.postgresql:
        return PostgresDriver.withConfig(
          host: host,
          port: port,
          database: database,
          username: username,
          password: password,
          sslEnabled: sslEnabled,
          caCertificatePem: caCertificatePem,
        );
      case DatabaseType.mysql:
      case DatabaseType.mariadb:
        return MysqlDriver.withConfig(
          host: host,
          port: port,
          database: database,
          username: username,
          password: password,
        );
    }
  }
}
