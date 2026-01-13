import '../../domain/entities/template.dart';

class TemplateModel extends Template {
  const TemplateModel({
    super.id,
    required super.titulo,
    required super.conteudo,
    required super.tags,
    super.markdownEnabled = true,
    super.snippetsEnabled = true,
  });

  factory TemplateModel.fromEntity(Template template) {
    return TemplateModel(
      id: template.id,
      titulo: template.titulo,
      conteudo: template.conteudo,
      tags: template.tags,
      markdownEnabled: template.markdownEnabled,
      snippetsEnabled: template.snippetsEnabled,
    );
  }

  factory TemplateModel.fromMap(Map<String, dynamic> map) {
    final tagsString = map['tags'] as String?;
    final tags = tagsString != null && tagsString.isNotEmpty
        ? tagsString.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
        : <String>[];

    return TemplateModel(
      id: map['id'] as int?,
      titulo: map['titulo'] as String,
      conteudo: map['conteudo'] as String,
      tags: tags,
      markdownEnabled: (map['markdown_enabled'] as int?) == 1,
      snippetsEnabled: (map['snippets_enabled'] as int?) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'titulo': titulo,
      'conteudo': conteudo,
      'markdown_enabled': markdownEnabled ? 1 : 0,
      'snippets_enabled': snippetsEnabled ? 1 : 0,
    };
  }

  Template toEntity() {
    return Template(
      id: id,
      titulo: titulo,
      conteudo: conteudo,
      tags: tags,
      markdownEnabled: markdownEnabled,
      snippetsEnabled: snippetsEnabled,
    );
  }
}