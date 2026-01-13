class Template {
  final int? id;
  final String titulo;
  final String conteudo;
  final List<String> tags;
  final bool markdownEnabled;
  final bool snippetsEnabled;

  const Template({
    this.id,
    required this.titulo,
    required this.conteudo,
    required this.tags,
    this.markdownEnabled = true,
    this.snippetsEnabled = true,
  });

  Template copyWith({
    int? id,
    String? titulo,
    String? conteudo,
    List<String>? tags,
    bool? markdownEnabled,
    bool? snippetsEnabled,
  }) {
    return Template(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      conteudo: conteudo ?? this.conteudo,
      tags: tags ?? this.tags,
      markdownEnabled: markdownEnabled ?? this.markdownEnabled,
      snippetsEnabled: snippetsEnabled ?? this.snippetsEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Template &&
        other.id == id &&
        other.titulo == titulo &&
        other.conteudo == conteudo &&
        other.markdownEnabled == markdownEnabled &&
        other.snippetsEnabled == snippetsEnabled;
  }

  @override
  int get hashCode => Object.hash(id, titulo, conteudo, markdownEnabled, snippetsEnabled);
}