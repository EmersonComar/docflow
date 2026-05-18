# Guia de Desenvolvimento — Docflow

Este documento define o ciclo de desenvolvimento e as regras que **toda IA e todo colaborador** devem seguir ao implementar novas funcionalidades no projeto Docflow.

---

## Arquitetura

O projeto segue **Clean Architecture** em três camadas:

```
lib/
├── core/          # Utilitários e erros compartilhados (Result<T>, Failures, StringUtils)
├── domain/        # Entidades e contratos de repositório (puro Dart, sem Flutter)
├── data/          # Implementações: models, datasources, repositories
└── presentation/  # Providers (ChangeNotifier), screens e widgets
```

**Regra de dependência:** camadas internas nunca importam camadas externas.  
`domain` não conhece `data`. `data` não conhece `presentation`.

---

## Ciclo de Desenvolvimento (Feature Flow)

Para cada nova funcionalidade, siga esta ordem:

```
1. Domain   →   2. Data   →   3. Provider   →   4. UI   →   5. Testes   →   6. Análise
```

### 1. Domain
- Adicione/modifique a **entidade** em `lib/domain/entities/`
- Atualize o **contrato** do repositório em `lib/domain/repositories/`

### 2. Data
- Atualize o **model** em `lib/data/models/` (`fromMap`, `toMap`)
- **NÃO** manipule SQL direto — use apenas `DatabaseDriver`
- Novos campos no banco: use `DatabaseDriver.insertTemplate()`, etc.
- Implemente o método no **repositório** em `lib/data/repositories/`
- **Migrations são gerenciadas pelo `SqliteDriftDriver`** (não edite manualmente)

**Importante:** O projeto agora é agnóstico de banco de dados através de `DatabaseDriver`.
Veja [ARCHITECTURE.md](./ARCHITECTURE.md) para detalhes e como adicionar novos bancos.

### 3. Provider
- Exponha o novo comportamento no `TemplateProvider` ou crie um novo provider

### 4. UI
- Atualize ou crie screens/widgets em `lib/presentation/`
- Adicione strings de localização nos arquivos `.arb` em `lib/l10n/`

### 5. Testes ← **Obrigatório**
- Veja a seção [Regras de Testes](#regras-de-testes) abaixo

### 6. Análise
```bash
flutter analyze   # deve retornar "No issues found!"
flutter test      # deve retornar "All tests passed!"
```

**Nunca** faça commit com warnings no `flutter analyze` ou testes falhando.

**Veja também:** [SECURITY.md](./SECURITY.md) — Criptografia e gerenciamento de chaves.

---

## Regras de Testes

### Estrutura espelhada
Os testes espelham a estrutura de `lib/`:

```
test/
├── helpers/
│   └── test_helpers.dart          # Factories e utilitários de teste
├── core/                          # Testa lib/core/
├── domain/                        # Testa lib/domain/
├── data/                          # Testa lib/data/
└── presentation/
    ├── template_provider_test.dart
    ├── template_provider_test.mocks.dart  ← gerado, não editar manualmente
    └── widgets/
```

### O que testar por camada

| Camada | Tipo de teste | Ferramenta |
|---|---|---|
| `core/` | Unit | `flutter_test` puro |
| `domain/entities/` | Unit | `flutter_test` puro |
| `data/models/` | Unit | `flutter_test` puro |
| `data/repositories/` | Integration (banco em memória) | `sqflite_common_ffi` |
| `presentation/providers/` | Unit com mock | `mockito` |
| `presentation/widgets/` | Widget test | `flutter_test` |

### Regras obrigatórias

1. **Toda nova entidade** deve ter testes de construtor, `copyWith`, `==` e `hashCode`.
2. **Toda nova operação no repositório** deve ter pelo menos um teste de sucesso e um de falha.
3. **Todo novo método no Provider** deve ter teste de fluxo de sucesso e de erro.
4. **Novos widgets** com lógica de estado devem ter pelo menos um widget test.
5. **Nunca** adicione dados ao banco de produção nos testes — use sempre `LocalDatabase.inMemory()`.
6. **Nunca** use `ensureInitialized()` nos testes de integração — use `TemplateRepositoryImpl.preInitialized()` para evitar o seed de dados de exemplo.

### Testes de integração com banco em memória

```dart
// setUp padrão para testes de repositório
setUp(() async {
  database = LocalDatabase.inMemory();
  await database.initialize();
  repository = TemplateRepositoryImpl.preInitialized(database);
});

tearDown(() async {
  await database.close();
});
```

### Mocks — quando regenerar

Sempre que o contrato de `TemplateRepository` ou a interface de `FlutterSecureStorage` mudar (novo método, assinatura alterada, atualização do pacote), rode:

```bash
dart run build_runner build
```

Os arquivos `*.mocks.dart` são **gerados automaticamente** — nunca os edite manualmente.

---

## Comandos do Dia a Dia

```bash
# Rodar todos os testes (verboso)
flutter test --reporter expanded

# Rodar um arquivo específico
flutter test test/data/template_repository_impl_test.dart --reporter expanded

# Rodar testes filtrados por nome
flutter test --name "create"

# Análise estática
flutter analyze

# Regenerar mocks após mudar TemplateRepository ou atualizar flutter_secure_storage
dart run build_runner build

# Build de produção (Linux)
flutter build linux
```

---

## Migrations de Banco de Dados

Ao adicionar/alterar colunas no SQLite:

1. Crie uma nova classe `MigrationVN` em `local_database.dart`
2. Incremente `_currentVersion`
3. Adicione a nova migração à lista `_migrations`
4. Atualize o model correspondente (`fromMap`, `toMap`)
5. **Escreva um teste de integração** que verifique os novos campos

```dart
// Exemplo de nova migration
class MigrationV4 implements Migration {
  @override
  int get version => 4;

  @override
  Future<void> up(Database db) async {
    await db.execute('ALTER TABLE templates ADD COLUMN novo_campo TEXT');
  }

  @override
  Future<void> down(Database db) async {}
}
```

---

## Localização (i18n)

Toda string visível ao usuário deve estar nos arquivos `.arb`:

- `lib/l10n/app_pt.arb` — Português (idioma principal)
- `lib/l10n/app_en.arb` — Inglês
- `lib/l10n/app_es.arb` — Espanhol

Após editar os `.arb`, rode `flutter gen-l10n` ou simplesmente `flutter run` para regenerar.  
**Nunca** use strings literais hardcoded em widgets.

---

## Checklist antes do Commit

- [ ] `flutter analyze` → **No issues found!**
- [ ] `flutter test` → **All tests passed!**
- [ ] Novos arquivos de teste adicionados para a funcionalidade
- [ ] Strings novas adicionadas nos três arquivos `.arb`
- [ ] Migrations documentadas e testadas (se houver mudança de schema)
- [ ] Mocks regenerados (se `TemplateRepository` ou `FlutterSecureStorage` foi alterado)
- [ ] Testes com `AppConfigService` usam `InMemoryKeyProvider` (não dependem do keyring real)

---

## Arquitetura de Banco de Dados — Multi-BD

**A partir da v2.1.0**, o projeto é agnóstico de banco de dados através de abstrações.

### Estrutura

```
lib/data/datasources/drivers/
├── database_driver.dart         ← Interface que todo BD deve implementar
├── sqlite_drift_driver.dart     ← ✅ SQLite (atual)
├── postgres_driver.dart         ← 🔄 PostgreSQL (futuro)
├── mysql_driver.dart            ← 🔄 MySQL/MariaDB (futuro)
└── driver_factory.dart          ← Factory para criar drivers
```

### Adicionar Novo Banco de Dados

1. Criar novo arquivo `seu_banco_driver.dart` implementando `DatabaseDriver`
2. Registrar em `DriverFactory`
3. Adicionar dependência no `pubspec.yaml`
4. Testes automaticamente funcionam — nenhuma mudança em camadas superiores

**Detalhes completos em [ARCHITECTURE.md](./ARCHITECTURE.md)**

---

## AppConfigService — Configuração do Aplicativo

Persistência de configurações **independente do banco de dados** (como o caminho do último `.db` usado):

- Arquivo: `lib/core/services/app_config_service.dart`
- Localização: `~/.local/share/docflow/app_config.json`
- Injetar `configDir` para testes: `AppConfigService(configDir: tempDir)`

```dart
// Produção
final config = AppConfigService();

// Testes
final config = AppConfigService(configDir: Directory.systemTemp.createTempSync('test_'));
```

## DatabaseProvider — Gerenciamento do Banco Ativo

O `DatabaseProvider` é a raiz de todos os providers dependentes de banco:

```
DatabaseProvider
   ├── ThemeNotifier
   ├── LocaleProvider
   ├── ChangelogProvider
   └── TemplateProvider (via TemplateRepositoryImpl)
```

- Para criar um novo banco (com seed de dados de exemplo): `DatabaseProvider.createDatabase(path)`
- Para abrir um banco existente (sem seed): `DatabaseProvider.openDatabase(path)`
- Para conectar ao PostgreSQL: `DatabaseProvider.openPostgresDatabase(credentials)`
- Para abertura automática na inicialização: `DatabaseProvider.tryAutoOpen()` (prioriza PostgreSQL se houver credenciais salvas)

### Segurança e Credenciais Remotas

As credenciais de PostgreSQL são persistidas de forma criptografada usando o `EncryptionService` com chave gerenciada pelo **keyring do sistema operacional** (GNOME Keyring / KWallet no Linux). A chave nunca é armazenada no código ou em texto plano no disco.

Ao alternar entre SQLite e PostgreSQL, o provider automaticamente limpa a configuração do banco anterior para garantir uma sessão limpa.

**Detalhes completos em [SECURITY.md](./SECURITY.md)**.

### Testando PostgreSQL

Para validar mudanças no driver PostgreSQL:
1. Use os testes unitários em `test/data/models/template_model_test.dart` para garantir que o casting de booleanos (int vs bool) funcione para ambos os bancos.
2. Utilize o formulário de conexão na `WelcomeScreen` (aba Conexão Remota).
3. Verifique os logs de conexão no console em caso de falha de SSL ou credenciais inválidas.


OBS: Não adicionar comentário nos arquivos Dart/Flutter.