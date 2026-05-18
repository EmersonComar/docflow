# Guia de Migração para Arquitetura Multi-BD — Docflow v2.1.0

## O que Mudou?

O projeto agora utiliza uma arquitetura agnóstica de banco de dados através de abstrações, preparando-o para suportar múltiplos bancos relacionais (PostgreSQL, MySQL/MariaDB) no futuro.

### ✨ Benefícios

- **Agnóstico de BD**: Trocar de banco é questão de configuração
- **Type-safe queries**: QueryBuilder agnóstico
- **Sem breaking changes**: Código existente continua funcionando
- **Zero alterações em Domain/Presentation**: Apenas Data layer evoluiu
- **Testes mantêm 100% cobertura**: 128 testes passando

## Mudanças na Estrutura

### Antes (v2.0.x)

```
lib/data/datasources/
├── local_database.dart    ← SQL raw + migrations acopladas ao Sqflite
└── initial_data.dart
```

### Depois (v2.1.0+)

```
lib/data/datasources/
├── drivers/
│   ├── database_driver.dart        ← Interface nova: padrão para todos os BDs
│   ├── migration.dart              ← Abstração agnóstica
│   ├── query_builder.dart          ← Construtor de queries portável
│   ├── sqlite_drift_driver.dart    ← Implementação SQLite
│   ├── postgres_driver.dart        ← Placeholder para PostgreSQL
│   ├── mysql_driver.dart           ← Placeholder para MySQL
│   ├── driver_factory.dart         ← Factory para escolher driver
│   └── drivers.dart                ← Barrel file
├── migrations/
│   └── v1_initial_schema.dart      ← Migrations agnósticas (futuro)
├── local_database.dart             ← Agora é FACHADA do driver
└── initial_data.dart
```

## Compatibilidade Retroativa

✅ **100% compatível** — Nada quebrou!

```dart
// Código antigo continua funcionando
final db = LocalDatabase();
await db.initialize();
final templates = await db.queryTemplates();
```

A interface pública de `LocalDatabase` é idêntica. Internamente, ela delega para `SqliteDriftDriver`.

## Próximas Fases

### v2.2.0 (PostgreSQL)
- [ ] Usar Drift ORM completo (type-safe queries)
- [ ] Implementar PostgresDriver com drift_postgresql
- [ ] Connection pooling para rede
- [ ] Testes de integração com TestContainers

### v2.3.0 (MySQL/MariaDB)
- [ ] Implementar MysqlDriver com drift_mysql
- [ ] CLI de setup de banco remoto
- [ ] Migração de dados SQLite → PostgreSQL

### v2.4.0 (Produção)
- [ ] Dashboard de admin para gerenciar bancos
- [ ] Suporte a múltiplas instâncias simultâneas
- [ ] Replicação de dados

## Como Desenvolver com Novo BD

```dart
// 1. Criar driver
import 'package:docflow/data/datasources/drivers/database_driver.dart';

class MeuBancoDriver implements DatabaseDriver {
  @override
  Future<void> initialize() async { ... }

  @override
  Future<int> insertTemplate({...}) async { ... }
  
  // Implementar todos os 8 métodos de DatabaseDriver
}

// 2. Registrar em DriverFactory
enum DatabaseType {
  sqlite,
  postgresql,
  mysql,
  mariadb,
  meuBanco,  // ← Adicionar aqui
}

// 3. Usar em LocalDatabase
final db = LocalDatabase(); // Automático SQLite para compatibilidade
```

## Testes

### Cambiar o Banco de Testes

```dart
// Atualmente: sempre SQLite em memória
setUp(() async {
  database = LocalDatabase.inMemory();
  await database.initialize();
});

// No futuro: poder escolher via variável de ambiente
enum TestDatabaseType { sqlite, postgresql }
final testDbType = Platform.environment['TEST_DB'] ?? 'sqlite';
```

### Coverage

- ✅ 146 testes passando
- ✅ 0 novos warnings
- ✅ `flutter analyze` — No issues found!

## Documentação Adicional

- [ARCHITECTURE.md](./ARCHITECTURE.md) — Design detalhado da arquitetura multi-BD
- [DEVELOPMENT.md](./DEVELOPMENT.md) — Ciclo de desenvolvimento
- [SECURITY.md](./SECURITY.md) — Criptografia e gerenciamento de chaves

## Perguntas Frequentes

**P: Posso usar PostgreSQL agora?**  
R: Sim! O suporte a PostgreSQL está disponível desde a v2.2.0. Use o formulário de Conexão Remota na `WelcomeScreen`.

**P: Preciso mudar algo no meu código?**  
R: Não! Está 100% compatível.

**P: Como contribuir com PostgreSQL?**  
R: Veja [ARCHITECTURE.md](./ARCHITECTURE.md) na seção "Implementar Novo Banco de Dados".

**P: Migrei de v2.1.x para v2.2.0 e minhas credenciais PostgreSQL sumiram. Por quê?**  
R: A v2.2.0 substituiu a chave de criptografia hardcoded por uma chave gerada no keyring do SO. Credenciais cifradas com a chave antiga são irrecuperáveis. Reinsira os dados de conexão — isso é necessário apenas uma vez. Veja [SECURITY.md](./SECURITY.md).

---

**Status**: ✅ Fase 1 e Fase 2 concluídas. PostgreSQL disponível + criptografia segura via keyring.
