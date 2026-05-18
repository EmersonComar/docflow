# Segurança e Criptografia — Docflow

## Visão Geral

A partir da **v2.2.0**, o Docflow protege credenciais sensíveis (como senhas de PostgreSQL) usando criptografia AES-256-CBC com chave gerenciada pelo keyring do sistema operacional. A chave **nunca** aparece no código-fonte, em arquivos de configuração, ou em texto plano no disco.

---

## Arquitetura

```
AppConfigService
    └── EncryptionService          ← encrypt() / decrypt()
            └── KeyProvider        ← contrato para obter a chave mestra
                    ├── KeyringKeyProvider    ← Produção (keyring do SO)
                    └── InMemoryKeyProvider  ← Testes (sem dependência de SO)
```

### Arquivos relevantes

| Arquivo | Responsabilidade |
|---|---|
| `lib/core/services/encryption_service.dart` | Criptografia AES-256-CBC com IV aleatório por operação |
| `lib/core/services/keyring_key_provider.dart` | Abstração `KeyProvider` + implementações de produção e teste |
| `lib/core/services/app_config_service.dart` | Usa `EncryptionService` para salvar/carregar credenciais |

---

## Como Funciona

### 1. Gerenciamento da Chave Mestra

Na primeira execução, `KeyringKeyProvider` gera uma chave AES-256 aleatória (32 bytes) e a armazena no **keyring do sistema operacional** via `flutter_secure_storage`:

- **Linux**: GNOME Keyring ou KWallet (via `libsecret`)
- **Windows**: Windows Credential Manager
- **macOS**: Keychain

```
Primeira execução                  Execuções subsequentes
─────────────────                  ──────────────────────
Gerar chave aleatória              Ler chave do keyring
        │                                   │
Salvar no keyring                           │
        │                                   │
        └───────────────────────────────────┘
                          │
                  EncryptionService
              (usa a chave para AES-CBC)
```

A chave fica sob a chave de lookup `docflow_master_key` no keyring.

### 2. Criptografia (encrypt)

Cada operação de criptografia gera um **IV aleatório de 16 bytes** independente. O IV é prefixado ao ciphertext antes de ser codificado em Base64:

```
plaintext ──► AES-256-CBC ──► [IV (16 bytes) | ciphertext] ──► Base64
                  ▲
              IV aleatório
           (gerado por operação)
```

Resultado armazenado em `app_config.json`:
```json
{
  "postgres_credentials": "<Base64 com IV prefixado>"
}
```

### 3. Descriptografia (decrypt)

O IV é extraído dos primeiros 16 bytes do dado decodificado, e o restante é descriptografado com a chave do keyring:

```
Base64 ──► decodifica ──► [IV (16 bytes) | ciphertext] ──► AES-256-CBC ──► plaintext
                                                                ▲
                                                         chave do keyring
```

---

## Por Que É Seguro

| Propriedade | Implementação |
|---|---|
| **Chave fora do código** | Keyring do SO — nunca no repositório ou binário |
| **IV único por operação** | Mesmo plaintext gera ciphertexts diferentes |
| **AES-256-CBC** | Padrão da indústria para dados em repouso |
| **Falha explícita** | `KeyringUnavailableException` em vez de fallback inseguro |
| **Isolamento de instâncias** | Vazamento de uma instalação não compromete outras |

---

## Graceful Degradation (Keyring Indisponível)

Se o keyring não estiver disponível (ex.: servidor headless, CI/CD), o `AppConfigService` captura a `KeyringUnavailableException`, loga um aviso e trata as credenciais como ausentes. O app continua funcional usando SQLite.

```
[AppConfigService] Aviso: keyring indisponível. Credenciais PostgreSQL
não poderão ser salvas/carregadas. Detalhe: ...
```

---

## Uso em Código

### Produção (automático via AppConfigService)

O `AppConfigService` inicializa o `EncryptionService` internamente de forma lazy. Nenhuma configuração adicional é necessária:

```dart
// main.dart — nada a fazer, é automático
final config = AppConfigService();
await config.savePostgresCredentials(credentials); // criptografa automaticamente
final creds = await config.loadPostgresCredentials(); // descriptografa automaticamente
```

### Injeção Manual (casos avançados)

```dart
// Criar o serviço com KeyringKeyProvider (padrão)
final encryption = await EncryptionService.create();

// Usar diretamente
final ciphertext = encryption.encrypt('texto secreto');
final original   = encryption.decrypt(ciphertext);
```

---

## Testes

Os testes **nunca** dependem do keyring do SO. Todos usam `InMemoryKeyProvider`:

```dart
setUp(() async {
  final encryption = await EncryptionService.create(
    keyProvider: InMemoryKeyProvider(),
  );
  service = AppConfigService(
    configDir: tempDir,
    encryptionService: encryption,
  );
});
```

### Regra obrigatória

> **Nunca** instancie `AppConfigService()` sem injetar `encryptionService` em testes.  
> Sem injeção, o serviço tentará acessar o keyring do SO — o que falha em ambientes de CI e testes unitários.

### Mocks do keyring

O `KeyringKeyProvider` pode ser testado com mock de `FlutterSecureStorage`:

```dart
@GenerateNiceMocks([MockSpec<FlutterSecureStorage>()])
import 'keyring_key_provider_test.mocks.dart';

// Simular ausência de chave (primeira execução)
when(mockStorage.read(key: anyNamed('key'))).thenAnswer((_) async => null);

// Simular falha de keyring
when(mockStorage.read(key: anyNamed('key')))
    .thenThrow(Exception('D-Bus connection failed'));
```

Após mudar a interface de `FlutterSecureStorage` (ex.: atualizar o pacote), regenere o mock:

```bash
dart run build_runner build
```

---

## Distribuição via Snap

Para que o keyring funcione em aplicações Snap com confinamento `strict`, o `snapcraft.yaml` deve declarar:

```yaml
apps:
  docflow:
    plugs:
      - password-manager-service  # ← Acesso ao keyring do SO

parts:
  docflow:
    build-packages:
      - libsecret-1-dev
      - libjsoncpp-dev
    stage-packages:
      - libsecret-1-0
      - libjsoncpp1
```

> **Nota:** O plug `password-manager-service` requer aprovação manual da Snap Store para publicação com confinamento `strict`.

---

## Migração da v2.1.x para v2.2.0

A versão anterior usava chave AES hardcoded no código. Após atualizar para v2.2.0, o app gerará uma nova chave aleatória no keyring. Credenciais PostgreSQL salvas com a versão antiga **não serão descriptografáveis** — o usuário precisará reinserir os dados de conexão. Nenhum dado SQLite é afetado.

Veja [MIGRATION_GUIDE.md](./MIGRATION_GUIDE.md) para detalhes completos.

---

## Dependências

| Pacote | Versão | Uso |
|---|---|---|
| `flutter_secure_storage` | `^10.2.0` | Acesso ao keyring do SO |
| `encrypt` | `^5.0.3` | AES-256-CBC |
| `pointycastle` | `^3.8.0` | Primitivas criptográficas (dependência indireta) |
