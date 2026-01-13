class BackendVersion {
  final String version;
  final List<String> changes;

  const BackendVersion({
    required this.version,
    required this.changes,
  });
}

const List<BackendVersion> changelogData = [
  BackendVersion(
    version: '1.4.0',
    changes: [
      'Adicionada opção para habilitar/desabilitar formatação Markdown e Snippets nos templates.',
      'Melhoria visual nas configurações do template.',
    ],
  ),
  BackendVersion(
    version: '1.3.5',
    changes: [
      'Implementação do visualizador de Changelog para acompanhar as novidades e atualizações do DocFlow.',
      """Adicionado suporte a Snippets nas anotações. Agora você pode definir variáveis dinâmicas utilizando chaves duplas, facilitando a reutilização de comandos.
      Exemplo: tcpdump -n -i {{interface}} host {{host}} and port {{port}}""",
    ],
  ),
];
