class BackendVersion {
  final String version;
  final Map<String, List<String>> localizedChanges;

  const BackendVersion({
    required this.version,
    required this.localizedChanges,
  });

  List<String> getChanges(String languageCode) {
    if (localizedChanges.containsKey(languageCode)) {
      return localizedChanges[languageCode]!;
    }
    return localizedChanges['pt'] ?? localizedChanges.values.first;
  }
}

const List<BackendVersion> changelogData = [
  BackendVersion(
    version: '3.0.0',
    localizedChanges: {
      'pt': [
        'Busca muito mais poderosa: a busca por texto agora usa indexação nativa do banco de dados (full-text search), com suporte a múltiplas palavras, busca por prefixo e resultados ordenados por relevância — encontre templates rapidamente mesmo com uma base grande.',
        'Ordenação de templates: escolha entre editado recentemente, criado recentemente ou ordem alfabética pelo título.',
        'Templates fixados: fixe os templates que você mais usa para que fiquem sempre no topo da lista.',
        'Tags mais inteligentes: autocomplete sugerindo tags já existentes ao digitar, contagem de uso de cada tag e busca dentro do próprio painel de tags — tags duplicadas por diferença de maiúsculas/minúsculas (ex.: "Bug" e "bug") agora são evitadas automaticamente.',
        'Conexão PostgreSQL mais segura: certificados do servidor agora são validados por padrão ao usar SSL, prevenindo ataques de interceptação (man-in-the-middle); também é possível conectar em servidores com certificado autoassinado enviando o certificado do servidor diretamente pelo formulário de conexão.',
        'Criptografia das credenciais do PostgreSQL atualizada para AES-256-GCM (autenticada), mais resistente a adulteração do que o padrão anterior. Por causa dessa mudança, pode ser necessário reinserir os dados de conexão uma única vez após atualizar.',
        'Maior confiabilidade: templates e suas tags agora são salvos de forma atômica (tudo ou nada em caso de falha), e o arquivo de configuração é protegido contra corrupção em caso de fechamento inesperado do aplicativo.',
      ],
      'en': [
        'Much more powerful search: text search now uses native full-text indexing, with support for multiple words, prefix matching, and results ranked by relevance — find your templates quickly even with a large collection.',
        'Template sorting: choose between recently edited, recently created, or alphabetical order by title.',
        'Pinned templates: pin the templates you use most so they always stay at the top of the list.',
        'Smarter tags: autocomplete suggests existing tags as you type, each tag shows how many templates use it, and you can search within the tags panel itself — duplicate tags from case differences (e.g. "Bug" vs "bug") are now avoided automatically.',
        "More secure PostgreSQL connections: server certificates are now validated by default when using SSL, preventing man-in-the-middle attacks; you can also connect to servers with a self-signed certificate by uploading the server's certificate directly in the connection form.",
        'Credential encryption upgraded to AES-256-GCM (authenticated), more resistant to tampering than the previous standard. Because of this change, you may need to re-enter your PostgreSQL connection details once after updating.',
        'Improved reliability: templates and their tags are now saved atomically (all-or-nothing on failure), and the configuration file is protected against corruption if the app closes unexpectedly.',
      ],
      'es': [
        'Búsqueda mucho más potente: la búsqueda de texto ahora usa indexación nativa de texto completo, con soporte para múltiples palabras, coincidencia por prefijo y resultados ordenados por relevancia — encuentre sus plantillas rápidamente incluso con una colección grande.',
        'Ordenación de plantillas: elija entre editado recientemente, creado recientemente u orden alfabético por título.',
        'Plantillas fijadas: fije las plantillas que más usa para que siempre aparezcan en la parte superior de la lista.',
        'Etiquetas más inteligentes: autocompletado que sugiere etiquetas ya existentes mientras escribe, cada etiqueta muestra cuántas plantillas la usan, y puede buscar dentro del propio panel de etiquetas — se evitan automáticamente etiquetas duplicadas por diferencias de mayúsculas/minúsculas (por ejemplo, "Bug" vs "bug").',
        'Conexiones PostgreSQL más seguras: los certificados del servidor ahora se validan por defecto al usar SSL, previniendo ataques de intermediario (man-in-the-middle); también puede conectarse a servidores con certificado autofirmado subiendo el certificado del servidor directamente en el formulario de conexión.',
        'Cifrado de credenciales actualizado a AES-256-GCM (autenticado), más resistente a la manipulación que el estándar anterior. Debido a este cambio, puede ser necesario volver a ingresar los datos de conexión de PostgreSQL una única vez después de actualizar.',
        'Mayor confiabilidad: las plantillas y sus etiquetas ahora se guardan de forma atómica (todo o nada en caso de fallo), y el archivo de configuración está protegido contra corrupción si la aplicación se cierra inesperadamente.',
      ],
    },
  ),
  BackendVersion(
    version: '2.2.0',
    localizedChanges: {
      'pt': [
        'Suporte a PostgreSQL: agora é possível conectar o DocFlow a um banco de dados remoto PostgreSQL através da tela de boas-vindas.',
        'Segurança aprimorada: as credenciais de acesso remoto são protegidas por criptografia AES-256 com chave gerenciada pelo keyring do sistema operacional (GNOME Keyring / KWallet). A chave nunca fica armazenada no código ou em disco.',
      ],
      'en': [
        'PostgreSQL support: it is now possible to connect DocFlow to a remote PostgreSQL database through the welcome screen.',
        'Enhanced security: remote access credentials are protected by AES-256 encryption with the key managed by the operating system keyring (GNOME Keyring / KWallet). The key is never stored in the code or on disk.',
      ],
      'es': [
        'Soporte para PostgreSQL: ahora es posible conectar DocFlow a una base de datos PostgreSQL remota a través de la pantalla de bienvenida.',
        'Seguridad mejorada: las credenciales de acceso remoto están protegidas por cifrado AES-256 con la clave gestionada por el keyring del sistema operativo (GNOME Keyring / KWallet). La clave nunca se almacena en el código ni en disco.',
      ],
    },
  ),
  BackendVersion(
    version: '2.1.0',
    localizedChanges: {
      'pt': [
        'Implementação da seleção dinâmica de banco de dados, permitindo criar múltiplos arquivos .db e escolher qual abrir.',
        'Nova tela de boas-vindas para o setup inicial.',
      ],
      'en': [
        'Implementation of dynamic database selection, allowing creating multiple .db files and choosing which one to open.',
        'New welcome screen for initial setup.',
      ],
      'es': [
        'Implementación de selección dinámica de base de datos, permitiendo crear múltiples archivos .db y elegir cuál abrir.',
        'Nueva pantalla de bienvenida para la configuración inicial.',
      ],
    },
  ),
  BackendVersion(
    version: '2.0.0',
    localizedChanges: {
      'pt': [
        'Atualização geral das dependências e otimização para compilação nativa no Linux.',
        '''Implementação de Atalhos de Teclado (Shortcuts) para maior produtividade:
      • Ctrl + N: Novo template
      • Ctrl + F: Pesquisar
      • Ctrl + T: Alternar tema (Claro/Escuro)
      • Ctrl + H: Abrir/Fechar Histórico de Novidades
      • Ctrl + L: Alternar idioma (PT/EN/ES)
      • Ctrl + S: Salvar template (No diálogo)
      • Ctrl + I: Importar Markdown (No diálogo)''',
      ],
      'en': [
        'General dependencies update and optimization for native Linux compilation.',
        '''Implementation of Keyboard Shortcuts for greater productivity:
      • Ctrl + N: New template
      • Ctrl + F: Search
      • Ctrl + T: Toggle theme (Light/Dark)
      • Ctrl + H: Open/Close News History
      • Ctrl + L: Toggle language (PT/EN/ES)
      • Ctrl + S: Save template (In dialog)
      • Ctrl + I: Import Markdown (In dialog)''',
      ],
      'es': [
        'Actualización general de dependencias y optimización para compilación nativa en Linux.',
        '''Implementación de Atajos de Teclado (Shortcuts) para mayor productividad:
      • Ctrl + N: Nuevo template
      • Ctrl + F: Buscar
      • Ctrl + T: Alternar tema (Claro/Oscuro)
      • Ctrl + H: Abrir/Cerrar Historial de Novedades
      • Ctrl + L: Cambiar idioma (PT/EN/ES)
      • Ctrl + S: Guardar template (En diálogo)
      • Ctrl + I: Importar Markdown (En diálogo)''',
      ],
    },
  ),
  BackendVersion(
    version: '1.4.0',
    localizedChanges: {
      'pt': [
        'Adicionada opção para habilitar/desabilitar formatação Markdown e Snippets nos templates.',
        'Melhoria visual nas configurações do template.',
      ],
      'en': [
        'Added option to enable/disable Markdown formatting and Snippets in templates.',
        'Visual improvement in template settings.',
      ],
      'es': [
        'Se agregó la opción para habilitar/deshabilitar el formato Markdown y los fragmentos en las plantillas.',
        'Mejora visual en la configuración de la plantilla.',
      ],
    },
  ),
  BackendVersion(
    version: '1.3.5',
    localizedChanges: {
      'pt': [
        'Implementação do visualizador de Changelog para acompanhar as novidades e atualizações do DocFlow.',
        '''Adicionado suporte a Snippets nas anotações. Agora você pode definir variáveis dinâmicas utilizando chaves duplas, facilitando a reutilização de comandos.
      Exemplo: tcpdump -n -i {{interface}} host {{host}} and port {{port}}''',
      ],
      'en': [
        'Implementation of the Changelog viewer to track news and updates in DocFlow.',
        '''Added support for Snippets in notes. Now you can define dynamic variables using double braces, making it easier to reuse commands.
      Example: tcpdump -n -i {{interface}} host {{host}} and port {{port}}''',
      ],
      'es': [
        'Implementación del visor de Changelog para rastrear novedades y actualizaciones en DocFlow.',
        '''Soporte agregado para fragmentos en las notas. Ahora puede definir variables dinámicas utilizando llaves dobles, lo que facilita la reutilización de comandos.
      Ejemplo: tcpdump -n -i {{interface}} host {{host}} and port {{port}}''',
      ],
    },
  ),
];
