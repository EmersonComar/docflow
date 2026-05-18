# Arquitetura de Banco de Dados — Docflow

## Abstração Multi-Banco

A partir da versão 2.1.0, o Docflow utiliza uma arquitetura agnóstica de banco de dados através de abstrações.

### Estrutura de Camadas

```
lib/data/datasources/
├── drivers/
│   ├── database_driver.dart         ← Interface abstrata (implementar para novo BD)
│   ├── migration.dart               ← Abstração de migrations
│   ├── query_builder.dart           ← Construtor de queries agnóstico
│   ├── driver_factory.dart          ← Factory para criar drivers
│   ├── sqlite_drift_driver.dart     ← ✅ Implementação SQLite (produção)
│   ├── postgres_driver.dart         ← 🔄 PostgreSQL (em desenvolvimento)
│   ├── mysql_driver.dart            ← 🔄 MySQL/MariaDB (em desenvolvimento)
│   └── drivers.dart                 ← Barrel file (exports)
├── migrations/
│   ├── v1_initial_schema.dart
│   ├── ...
│   └── (migrations agnósticas)
├── local_database.dart              ← Fachada de alto nível
└── initial_data.dart
```

## Como Usar

### Desenvolvimento Local (SQLite — Padrão)

```dart
import 'package:docflow/data/datasources/local_database.dart';

// Automático — SQLite local
final db = LocalDatabase();
await db.initialize();
```

### Trocar para PostgreSQL (Futuro)

```dart
import 'package:docflow/data/datasources/drivers/driver_factory.dart';

// Criar RemoteDatabase (a ser implementado)
final driver = DriverFactory.createRemoteDriver(
  DatabaseType.postgresql,
  host: 'db.exemplo.com',
  port: 5432,
  database: 'docflow',
  username: 'user',
  password: 'pass',
);
```

## Implementar Novo Banco de Dados

### 1. Criar novo Driver

```dart
// lib/data/datasources/drivers/seu_banco_driver.dart
import 'database_driver.dart';

class SeuBancoDriver implements DatabaseDriver {
  @override
  Future<void> initialize() async { ... }

  @override
  Future<void> close() async { ... }

  @override
  Future<int> insertTemplate({
    required String titulo,
    required String conteudo,
    required bool markdownEnabled,
    required bool snippetsEnabled,
  }) async { ... }

  // Implementar todos os métodos de DatabaseDriver
}
```

### 2. Registrar no DriverFactory

```dart
// lib/data/datasources/drivers/driver_factory.dart
enum DatabaseType {
  sqlite,
  postgresql,
  mysql,
  mariadb,
  seuBanco,  // ← Adicionar
}

class DriverFactory {
  static DatabaseDriver createDriver(DatabaseType type) {
    switch (type) {
      // ...
      case DatabaseType.seuBanco:
        return SeuBancoDriver();
      // ...
    }
  }
}
```

### 3. Adicionar dependências (pubspec.yaml)

```yaml
dependencies:
  seu_package_db: ^x.y.z
```

### 4. Testes

- Todos os DAOs devem funcionar sem modificação
- Migrations são agnósticas — não precisam mudar
- TemplateRepository não precisa mudar

## Status dos Drivers

| Driver | Status | Versão |
|--------|--------|--------|
| SQLite (Drift) | ✅ Pronto | v2.1.0 |
| PostgreSQL | ✅ Pronto | v2.2.0 |
| MySQL/MariaDB | 🔄 Desenvolvendo | v2.3.0 |

## Roadmap

- **v2.1.0** — Abstração + SQLite funcionando
- **v2.2.0** (Atual) — PostgreSQL + Criptografia segura via keyring do SO
- **v2.3.0** — MySQL/MariaDB suportado
- **v2.4.0** — Migrations automáticas Drift + CLI de setup

## Segurança

Credenciais de banco remoto são protegidas por criptografia AES-256-CBC com chave gerenciada pelo keyring do sistema operacional. Nenhuma chave é armazenada no código ou em texto plano.

**Detalhes completos em [SECURITY.md](./SECURITY.md)**.
