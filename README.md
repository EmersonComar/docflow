# DocFlow

Um gerenciador de templates e anotações construído com Flutter, focado em uma interface limpa, moderna e eficiente.

##  Sobre o Projeto

O DocFlow foi projetado para ajudar desenvolvedores, escritores e profissionais a armazenar e gerenciar snippets de código, respostas prontas, anotações e qualquer tipo de texto reutilizável. Com uma interface intuitiva e recursos de busca e filtragem, encontrar o que você precisa nunca foi tão rápido.

## Recursos

- **Temas Claro e Escuro:** Alterne facilmente entre os modos para melhor conforto visual.
- **Gerenciamento Completo de Templates:** Crie, edite e delete templates com facilidade através de um diálogo intuitivo.
- **Busca e Filtragem:** Encontre templates rapidamente com busca full-text (com relevância e suporte a prefixo/múltiplas palavras) por título/conteúdo, filtrando por múltiplas tags, ou buscando dentro da própria lista de tags.
- **Ordenação e Favoritos:** Ordene por editado recentemente, criado recentemente ou título, e fixe os templates mais usados no topo da lista.
- **Cards Expansíveis:** Visualize um trecho do conteúdo ou expanda o card com um clique para ver o texto completo.
- **Destaque de Sintaxe:** O DocFlow agora oferece destaque de sintaxe para blocos de código em Markdown, melhorando a legibilidade.
- **Copiar Código Facilmente:** Um botão "Copiar" foi adicionado aos blocos de código, permitindo que você os envie para a área de transferência com um único clique.
- **Banco de Dados Local:** Seus dados são armazenados de forma persistente em um banco de dados SQLite local.

## Tecnologias Utilizadas

- **Linguagem:** [Dart](https://dart.dev/)
- **Framework:** [Flutter](https://flutter.dev/)
- **Gerenciamento de Estado:** [Provider](https://pub.dev/packages/provider)
- **Banco de Dados:** [sqflite](https://pub.dev/packages/sqflite) com [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi) para suporte desktop.
- **Renderização de Markdown:** [gpt_markdown](https://pub.dev/packages/gpt_markdown)
- **Internacionalização:** [flutter_localizations](https://api.flutter.dev/flutter/flutter_localizations/flutter_localizations-library.html)
- **Design:** [Material 3](https://m3.material.io/)

## Instalação (linux via Snap)

O DocFlow está disponível na Snap Store. Para instalar, basta ter o `snapd` configurado em sua distribuição Linux e executar o comando abaixo.

```sh
sudo snap install docflow 
```

Após a instalação, você pode encontrar o DocFlow no menu de aplicativos do seu sistema.

[![Disponível na Snap Store](https://snapcraft.io/pt/dark/install.svg)](https://snapcraft.io/docflow)

## Internacionalização (i18n)

O DocFlow agora suporta múltiplos idiomas e detecta automaticamente o idioma do sistema. Também é possível escolher manualmente o idioma nas opções do aplicativo; a escolha do usuário é persistida localmente para que a preferência seja mantida entre execuções.

- Idiomas suportados: português (pt), inglês (en) e espanhol (es).
- Comportamento:
    - Padrão: segue o idioma do sistema quando nenhuma escolha explícita foi feita.
    - Troca manual: o usuário pode selecionar um idioma no menu do aplicativo; essa escolha é salva na base de dados local (`user_preferences`) e aplicada imediatamente.

Como adicionar um novo idioma:

1. Crie um arquivo ARB em `lib/l10n/` seguindo o padrão `app_xx.arb` (por exemplo, `app_fr.arb` para francês). Use as chaves existentes nos arquivos ARB atuais como referência.
2. Gere as classes de localização executando:

```bash
flutter gen-l10n --arb-dir=lib/l10n --template-arb-file=app_pt.arb --output-localization-file=app_localizations.dart --output-dir=lib/generated
```

3. Atualize qualquer string hard-coded para usar `AppLocalizations.of(context)!.yourKey` e adicione o novo idioma ao seletor de idioma, se desejar.

Observação: O código salva apenas o código do idioma (por exemplo, `pt`, `en`, `es`) na tabela `user_preferences` sob a chave `locale`. Se você precisar de variantes de região (por exemplo `pt_BR`), podemos ajustar a persistência para armazenar o locale completo.

## Desenvolvimento

Siga as instruções abaixo para obter uma cópia local do projeto e executá-la.

### Pré-requisitos

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (versão 3.x ou superior)
- Um editor de código como [VS Code](https://code.visualstudio.com/) ou [Android Studio](https://developer.android.com/studio).

### Instalação e Execução

1.  **Clone o repositório:**
    ```sh
    git clone https://github.com/EmersonComar/DocFlow.git
    cd DocFlow
    ```

2.  **Instale as dependências:**
    ```sh
    flutter pub get
    ```

3.  **Execute o aplicativo:**
    ```sh
    flutter run
    ```

O aplicativo deve iniciar no seu emulador, navegador ou dispositivo desktop conectado.