import '../../domain/entities/template.dart';

class TemplateModel extends Template {
  const TemplateModel({
    super.id,
    required super.titulo,
    required super.conteudo,
    required super.tags,
    super.markdownEnabled = true,
    super.snippetsEnabled = true,
    super.updatedAt,
    super.pinned = false,
  });

  factory TemplateModel.fromEntity(Template template) {
    return TemplateModel(
      id: template.id,
      titulo: template.titulo,
      conteudo: template.conteudo,
      tags: template.tags,
      markdownEnabled: template.markdownEnabled,
      snippetsEnabled: template.snippetsEnabled,
      updatedAt: template.updatedAt,
      pinned: template.pinned,
    );
  }

  factory TemplateModel.fromMap(Map<String, dynamic> map) {
    final tagsString = map['tags'] as String?;
    final tags = tagsString != null && tagsString.isNotEmpty
        ? tagsString.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
        : <String>[];

    final updatedAtRaw = map['updated_at'] as String?;

    return TemplateModel(
      id: map['id'] as int?,
      titulo: map['titulo'] as String,
      conteudo: map['conteudo'] as String,
      tags: tags,
      markdownEnabled: map['markdown_enabled'] == 1 || map['markdown_enabled'] == true,
      snippetsEnabled: map['snippets_enabled'] == 1 || map['snippets_enabled'] == true,
      updatedAt: updatedAtRaw != null ? DateTime.tryParse(updatedAtRaw) : null,
      pinned: map['pinned'] == 1 || map['pinned'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'titulo': titulo,
      'conteudo': conteudo,
      'markdown_enabled': markdownEnabled ? 1 : 0,
      'snippets_enabled': snippetsEnabled ? 1 : 0,
      'pinned': pinned ? 1 : 0,
      if (updatedAt != null) 'updated_at': updatedAt!.toUtc().toIso8601String(),
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
      updatedAt: updatedAt,
      pinned: pinned,
    );
  }
}
