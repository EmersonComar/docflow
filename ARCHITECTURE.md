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

## Busca, Ordenação e Organização (v3.0.0)

Pensado para quando a base de templates cresce e "procurar pela tag" deixa de bastar:

- **Busca textual de verdade**: `searchQuery` deixou de ser um `LIKE '%termo%'` (substring única, sem ranking) e passou a usar o mecanismo de full-text search nativo de cada banco:
  - **SQLite**: tabela virtual FTS5 (`templates_fts`, "external content" espelhando `titulo`+`conteudo`, sincronizada via triggers). Cada palavra digitada vira um termo `"palavra"*` (aspas neutralizam sintaxe especial do FTS5; `*` habilita prefixo — digitar "flu" já encontra "Flutter"). Resultados ordenados por relevância (`bm25`).
  - **PostgreSQL**: coluna gerada `search_vector tsvector` (config `'simple'`, sem stemming — o conteúdo mistura idiomas e trechos de código) + índice GIN. Busca via `websearch_to_tsquery`, que tolera texto livre sem lançar erro de sintaxe (aceita até `-palavra` para excluir um termo). Ranking via `ts_rank`.
  - Ambos migram automaticamente bancos existentes (`_onUpgrade` no SQLite via bump de versão de schema; `ALTER TABLE ... ADD COLUMN IF NOT EXISTS` idempotente no Postgres) — nenhuma ação do usuário necessária.
- **Ordenação** (`TemplateSortOption`, em `domain/entities/template_sort_option.dart`): editado recentemente (padrão — usa a nova coluna `updated_at`, estampada pelo driver em todo insert/update), criado recentemente (`id DESC`, comportamento antigo) ou título (A-Z). Durante uma busca, a relevância sempre tem prioridade sobre o critério escolhido.
- **Fixar (pin)**: `DatabaseDriver.setPinned(id, pinned)` — templates fixados aparecem primeiro na listagem, independente da ordenação ou de uma busca ativa.
- **Tags mais resistentes a duplicação**: o matching de tags passou a ser case-insensitive nos dois drivers (`"Bug"` reaproveita a tag `"bug"` já cadastrada em vez de criar uma nova) e o diálogo de template ganhou autocomplete (`TagInputField`) contra as tags existentes. `DatabaseDriver.queryTagCounts()` expõe quantos templates usam cada tag, usado no painel de filtros para mostrar contagem e permitir buscar dentro da própria lista de tags.

> Nenhuma dessas mudanças quebra bancos existentes — todas as colunas novas (`updated_at`, `pinned`, `search_vector`) são adicionadas de forma aditiva/idempotente na inicialização.

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
| SQLite | ✅ Pronto (+ FTS5 desde v3.0.0) | v2.1.0 |
| PostgreSQL | ✅ Pronto (+ tsvector/GIN e TLS com verificação desde v3.0.0) | v2.2.0 |
| MySQL/MariaDB | 🔄 Desenvolvendo | v3.1.0 (planejado) |

## Roadmap

- **v2.1.0** — Abstração + SQLite funcionando
- **v2.2.0** — PostgreSQL + Criptografia via keyring do SO
- **v3.0.0** (Atual) — Busca full-text (FTS5/tsvector), ordenação, templates fixados, tags com autocomplete; criptografia migrada para AES-256-GCM; TLS do PostgreSQL com verificação de certificado (+ suporte a certificado autoassinado)
- **v2.4.0** (planejado) — MySQL/MariaDB suportado

## Segurança

Credenciais de banco remoto são protegidas por criptografia autenticada AES-256-GCM (desde a v3.0.0; v2.2.x usava AES-256-CBC) com chave gerenciada pelo keyring do sistema operacional. Nenhuma chave é armazenada no código ou em texto plano. Conexões PostgreSQL com SSL habilitado usam `SslMode.verifyFull` desde a v3.0.0, validando certificado e hostname do servidor (com suporte a certificado autoassinado via upload).

**Detalhes completos em [SECURITY.md](./SECURITY.md)**.
