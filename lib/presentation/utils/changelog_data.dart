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
    version: '1.3.5',
    changes: [
      'Adicionado este campo de changelog para melhor comunicação referente às atualizações do DocFlow.',
      """Adicionado suporte para snippets nas anotações. Tais snippets permitem que seja possível criar trechos de anotações que serão inseridos no momento
      de copiar uma anotação. Para utilizar o snippet, basta digitar o nome do snippet entre chaves, por exemplo {{snippet_name}}. Um exemplo:
      tcpdump -n -i {{interface}} -host {{host}} -p {{port}}""",
    ],
  ),
];
