# Arquitetura de Banco de Dados — Docflow

## Abstração Multi-Banco

A partir da versão 2.1.0, o Docflow utiliza uma arquitetura agnóstica de banco de dados através de abstrações.

### Estrutura de Camadas

```
lib/data/datasources/
├── drivers/
│   ├── database_driver.dart         ← Interface abstrata (implementar para novo BD)
│   ├── driver_factory.dart          ← Factory para criar drivers
│   ├── sqlite_drift_driver.dart     ← ✅ Implementação SQLite via sqflite (produção)
│   ├── postgres_driver.dart         ← ✅ Implementação PostgreSQL (produção)
│   ├── mysql_driver.dart            ← 🔄 MySQL/MariaDB (em desenvolvimento)
│   └── drivers.dart                 ← Barrel file (exports)
├── local_database.dart              ← Fachada de alto nível
└── initial_data.dart
```

> `sqlite_drift_driver.dart` usa o pacote `sqflite` diretamente (não o pacote Drift, apesar do nome — herdado de um plano inicial de adotar Drift que não avançou). O schema e as migrações de cada driver vivem no próprio driver (`_onCreate`/`_onUpgrade` no SQLite, `CREATE TABLE IF NOT EXISTS` no Postgres) — não há mais uma camada de `Migration` agnóstica separada.
>
> **Sobre `sqlite3_flutter_libs`:** a versão `0.6.0+eol` disponível no pub.dev marca o pacote como descontinuado — a partir do `sqlite3` v3.x, o bundling de binários nativos passou a ser feito pelo próprio pacote `sqlite3`, tornando `sqlite3_flutter_libs` desnecessário. Ainda não migramos para esse novo esquema (o pacote atual, `^0.5.0`, continua funcional); fazer essa troca é um trabalho separado que exige validar o build nativo Linux do zero, não uma simples troca de versão no `pubspec.yaml`.

## Como Usar

### Desenvolvimento Local (SQLite — Padrão)

```dart
import 'package:docflow/data/datasources/local_database.dart';

// Automático — SQLite local
final db = LocalDatabase();
await db.initialize();
```

### Trocar para PostgreSQL

Disponível desde a v2.2.0 via `ExternalConnectionForm` na `WelcomeScreen`, que por baixo dos panos chama:

```dart
import 'package:docflow/data/datasources/drivers/driver_factory.dart';

final driver = DriverFactory.createRemoteDriver(
  DatabaseType.postgresql,
  host: 'db.exemplo.com',
  port: 5432,
  database: 'docflow',
  username: 'user',
  password: 'pass',
  sslEnabled: true, // usa SslMode.verifyFull — exige certificado válido
  caCertificatePem: certPemContent, // opcional: pinning para certificado autoassinado
);
```

> `DriverFactory.createDriver(DatabaseType.postgresql)` lança `UnsupportedError` de propósito — PostgreSQL sempre exige credenciais explícitas, então só `createRemoteDriver` é válido para esse tipo.
>
> `caCertificatePem` é opcional e só tem efeito quando `sslEnabled: true`. Quando fornecido, `PostgresDriver` confia **apenas** nesse certificado (não nas CAs públicas do sistema) — ver detalhes em [SECURITY.md](./SECURITY.md#suporte-a-certificado-autoassinado-pinning).

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

Credenciais de banco remoto são protegidas por criptografia autenticada AES-256-GCM com chave gerenciada pelo keyring do sistema operacional. Nenhuma chave é armazenada no código ou em texto plano. Conexões PostgreSQL com SSL habilitado usam `SslMode.verifyFull`, validando certificado e hostname do servidor.

**Detalhes completos em [SECURITY.md](./SECURITY.md)**.
