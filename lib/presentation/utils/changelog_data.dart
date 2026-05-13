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
