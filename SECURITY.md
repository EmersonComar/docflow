# Segurança e Criptografia — Docflow

## Visão Geral

A partir da **v2.2.0**, o Docflow protege credenciais sensíveis (como senhas de PostgreSQL) usando criptografia com chave gerenciada pelo keyring do sistema operacional. A chave **nunca** aparece no código-fonte, em arquivos de configuração, ou em texto plano no disco.

> **Nota:** a v2.2.0 usava AES-256-CBC (sem autenticação). A partir da **v3.0.0**, a criptografia migrou para **AES-256-GCM** (autenticada) — veja [Migração para AES-256-GCM](#migração-para-aes-256-gcm) abaixo.

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
| `lib/core/services/encryption_service.dart` | Criptografia AES-256-GCM (autenticada) com nonce aleatório por operação |
| `lib/core/services/keyring_key_provider.dart` | Abstração `KeyProvider` + implementações de produção e teste |
| `lib/core/services/app_config_service.dart` | Usa `EncryptionService` para salvar/carregar credenciais, com escrita atômica (temp file + rename) |

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
              (usa a chave para AES-GCM)
```

A chave fica sob a chave de lookup `docflow_master_key` no keyring.

### 2. Criptografia (encrypt)

Cada operação de criptografia gera um **nonce aleatório de 12 bytes** independente. Um byte de versão de formato (`0x02`, identificando AES-GCM) e o nonce são prefixados ao ciphertext (que já inclui a tag de autenticação do GCM) antes de codificar em Base64:

```
plaintext ──► AES-256-GCM ──► [versão (1B) | nonce (12B) | ciphertext+tag] ──► Base64
                                    ▲
                              nonce aleatório
                           (gerado por operação)
```

Resultado armazenado em `app_config.json`:
```json
{
  "postgres_credentials": "<Base64 com versão + nonce prefixados>"
}
```

Por ser AEAD (autenticação + criptografia), qualquer adulteração do ciphertext — por exemplo, alguém editando `app_config.json` manualmente — faz a descriptografia falhar de forma detectável, em vez de produzir um plaintext corrompido silenciosamente (o risco de maleabilidade do AES-CBC "puro").

### 3. Descriptografia (decrypt)

O byte de versão é conferido, o nonce é extraído dos 12 bytes seguintes, e o restante é descriptografado (e autenticado) com a chave do keyring:

```
Base64 ──► decodifica ──► [versão | nonce (12B) | ciphertext+tag] ──► AES-256-GCM ──► plaintext
                                                                            ▲
                                                                     chave do keyring
```

Dados que não começam com o byte de versão `0x02` (por exemplo, ciphertext no formato CBC legado, sem esse marcador) são rejeitados e tratados como "credencial ausente" — o mesmo comportamento usado para dados corrompidos ou chave divergente.

---

## Por Que É Seguro

| Propriedade | Implementação |
|---|---|
| **Chave fora do código** | Keyring do SO — nunca no repositório ou binário |
| **Nonce único por operação** | Mesmo plaintext gera ciphertexts diferentes |
| **AES-256-GCM (AEAD)** | Confidencialidade + autenticação — adulteração do ciphertext é detectada |
| **Falha explícita** | `KeyringUnavailableException` em vez de fallback inseguro |
| **Isolamento de instâncias** | Vazamento de uma instalação não compromete outras |
| **Escrita atômica do config** | `app_config.json` é gravado via temp file + rename — um crash no meio da escrita não corrompe o arquivo |

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

## Conexão PostgreSQL: TLS e verificação de certificado (v3.0.0+)

Quando o usuário ativa "SSL Enabled" no formulário de conexão remota, o `PostgresDriver` abre a conexão com `SslMode.verifyFull` — o modo mais estrito do pacote `postgres`, que:

1. Criptografa a conexão (como qualquer modo SSL/TLS faria);
2. **Valida a cadeia do certificado** apresentado pelo servidor contra o trust store do sistema;
3. **Confere se o hostname** do certificado corresponde ao host configurado.

> **Por que não `SslMode.require`?** Esse modo criptografa a conexão mas **ignora erros de verificação de certificado** — a própria documentação do pacote `postgres` alerta que ele aceita qualquer certificado, inclusive um forjado por um atacante na rede (man-in-the-middle via ARP/DNS spoofing, Wi-Fi público, etc.). Isso tornaria o toggle "SSL Enabled" da UI enganoso: o usuário veria "conexão segura" sem a proteção real de MITM que o nome sugere. O toggle "SSL Enabled" existe desde a v2.2.0; até a v2.2.x ele usava `SslMode.require` — a validação de certificado (`verifyFull`) é nova na v3.0.0.

**Implicação prática:** servidores PostgreSQL com certificado autoassinado (comum em instalações internas/self-hosted) não são aceitos com SSL habilitado usando apenas o trust store padrão do sistema — a menos que o usuário forneça o certificado do servidor explicitamente (ver seção seguinte).

### Suporte a certificado autoassinado (pinning) (v3.0.0+)

Na tela de conexão remota, quando "SSL Enabled" está ativo, um segundo toggle "Certificado autoassinado" permite selecionar o arquivo de certificado (`.pem`/`.crt`/`.cer`) do próprio servidor. O conteúdo do certificado é lido e guardado junto das demais credenciais (campo `caCertificatePem` em `PostgresCredentials`, persistido criptografado como o resto).

Internamente, `buildSecurityContext()` (em `postgres_driver.dart`) cria um `SecurityContext` com `withTrustedRoots: false` e adiciona **apenas** esse certificado como confiável:

```dart
final context = SecurityContext(); // sem as CAs públicas do sistema
context.setTrustedCertificatesBytes(utf8.encode(caCertificatePem));
```

Isso é usado junto com `SslMode.verifyFull` — ou seja, a conexão só é aceita se o servidor apresentar **exatamente** esse certificado (mais restritivo que confiar em qualquer CA pública, e continua eficaz contra man-in-the-middle mesmo sem uma CA real por trás: um atacante que apresentar qualquer outro certificado — inclusive um "parecido" — é rejeitado). `SslMode.verifyFull` também confere o hostname do certificado contra o host configurado, então o certificado autoassinado precisa ter o CN/SAN correspondente ao host usado na conexão.

Validado manualmente contra um PostgreSQL real com certificado autoassinado: conexão sem certificado é rejeitada, conexão com um certificado diferente do servidor é rejeitada, e conexão com o certificado correto do servidor funciona normalmente (incluindo operações de CRUD sobre a conexão).

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

## Migração para AES-256-GCM (v2.2.x → v3.0.0)

`EncryptionService` passou de AES-256-CBC para AES-256-GCM (autenticado). O novo formato de ciphertext (prefixado com um byte de versão `0x02`) não é compatível com dados cifrados pela versão anterior.

**Efeito prático:** após atualizar, credenciais PostgreSQL salvas com a versão CBC não serão descriptografáveis — `loadPostgresCredentials()` retorna `null`, exatamente como no cenário de "keyring indisponível" já suportado. O app continua funcional; o usuário só precisa reabrir o formulário de conexão remota e reinserir os dados **uma única vez**. Nenhum dado SQLite é afetado, e a chave mestra no keyring não muda (só o algoritmo que a usa).

---

## Dependências

| Pacote | Versão | Uso |
|---|---|---|
| `flutter_secure_storage` | `^10.2.0` (resolvido: 10.3.1) | Acesso ao keyring do SO |
| `encrypt` | `^5.0.3` | AES-256-GCM |
| `pointycastle` | resolvido via `encrypt` (não é mais dependência direta) | Primitivas criptográficas |
| `postgres` | `^3.3.1` (resolvido: 3.5.12) | Driver PostgreSQL — `SslMode.verifyFull` para TLS com verificação de certificado |

> **Por que `flutter_secure_storage` não está na v11.x:** a v11 exige `flutter_secure_storage_windows ^4.2.2`, que por sua vez exige `win32 ^6.0.1` — incompatível com a faixa de `win32` que `file_picker` (na versão estável mais recente) ainda usa. Subir para a v11 hoje exigiria adotar `file_picker` em beta (`^12.0.0-beta.7`), o que não faz sentido para um app em produção só por causa de um pacote Windows que o Docflow (Linux-only) nem exercita. Revisar quando `file_picker` estabilizar a v12.
