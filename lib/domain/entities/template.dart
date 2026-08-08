class Template {
  final int? id;
  final String titulo;
  final String conteudo;
  final List<String> tags;
  final bool markdownEnabled;
  final bool snippetsEnabled;


  final DateTime? updatedAt;

  final bool pinned;

  const Template({
    this.id,
    required this.titulo,
    required this.conteudo,
    required this.tags,
    this.markdownEnabled = true,
    this.snippetsEnabled = true,
    this.updatedAt,
    this.pinned = false,
  });

  Template copyWith({
    int? id,
    String? titulo,
    String? conteudo,
    List<String>? tags,
    bool? markdownEnabled,
    bool? snippetsEnabled,
    DateTime? updatedAt,
    bool? pinned,
  }) {
    return Template(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      conteudo: conteudo ?? this.conteudo,
      tags: tags ?? this.tags,
      markdownEnabled: markdownEnabled ?? this.markdownEnabled,
      snippetsEnabled: snippetsEnabled ?? this.snippetsEnabled,
      updatedAt: updatedAt ?? this.updatedAt,
      pinned: pinned ?? this.pinned,
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
        other.snippetsEnabled == snippetsEnabled &&
        other.updatedAt == updatedAt &&
        other.pinned == pinned;
  }

  @override
  int get hashCode => Object.hash(
        id,
        titulo,
        conteudo,
        markdownEnabled,
        snippetsEnabled,
        updatedAt,
        pinned,
      );
}
