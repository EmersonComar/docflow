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
│   ├── sqlite_drift_driver.dart    ← Implementação SQLite (sqflite; apesar do nome, não usa o pacote Drift)
│   ├── postgres_driver.dart        ← Implementação PostgreSQL
│   ├── mysql_driver.dart           ← Placeholder para MySQL
│   ├── driver_factory.dart         ← Factory para escolher driver
│   └── drivers.dart                ← Barrel file
├── local_database.dart             ← Agora é FACHADA do driver
└── initial_data.dart
```

> **Nota:** `migration.dart`, `query_builder.dart` e `migrations/v1_initial_schema.dart` foram removidos por não terem nenhum uso real — eram abstrações preparadas para uma futura adoção do pacote Drift que nunca chegou a ser usada (o schema é criado/migrado diretamente por cada driver, via `_onCreate`/`_onUpgrade` no SQLite e `CREATE TABLE IF NOT EXISTS` no Postgres). As dependências `drift` e `drift_dev` também saíram do `pubspec.yaml` pelo mesmo motivo.

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
- [x] Implementar `PostgresDriver` com o pacote `postgres` (SQL nomeado, sem ORM)
- [x] TLS com verificação de certificado (`SslMode.verifyFull`)
- [x] Criar/atualizar template e tags em uma única transação (`runTx`)
- [ ] Connection pooling para rede
- [ ] Testes de integração automatizados contra um Postgres real (hoje validado manualmente; ver nota abaixo)

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

- ✅ 148 testes passando
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

**P: Atualizei o Docflow e agora preciso reinserir a senha do PostgreSQL de novo. Por quê?**  
R: A criptografia das credenciais migrou de AES-256-CBC para AES-256-GCM (autenticado). É o mesmo tipo de migração de formato da pergunta anterior — necessária uma única vez. Veja [SECURITY.md](./SECURITY.md#migração-para-aes-256-gcm).

**P: Habilitei "SSL Enabled" e agora não consigo mais conectar no meu Postgres self-hosted. Por quê?**  
R: A conexão SSL passou a exigir um certificado válido (`SslMode.verifyFull`), em vez de apenas criptografar sem validar (`SslMode.require`, vulnerável a man-in-the-middle). Certificados autoassinados não são aceitos a menos que a CA esteja no trust store do sistema. Veja [SECURITY.md](./SECURITY.md#conexão-postgresql-tls-e-verificação-de-certificado).

---

**Status**: ✅ Fase 1 e Fase 2 concluídas. PostgreSQL disponível + criptografia segura via keyring.
