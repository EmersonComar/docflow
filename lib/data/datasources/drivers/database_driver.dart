import '../../../domain/entities/template_sort_option.dart';

abstract class DatabaseDriver {
  Future<void> initialize();
  Future<void> close();

  Future<int> insertTemplate({
    required String titulo,
    required String conteudo,
    required bool markdownEnabled,
    required bool snippetsEnabled,
  });

  Future<int> updateTemplate({
    required int id,
    required String titulo,
    required String conteudo,
    required bool markdownEnabled,
    required bool snippetsEnabled,
  });

  Future<int> createTemplateWithTags({
    required String titulo,
    required String conteudo,
    required bool markdownEnabled,
    required bool snippetsEnabled,
    required List<String> tags,
  });

  Future<void> updateTemplateWithTags({
    required int id,
    required String titulo,
    required String conteudo,
    required bool markdownEnabled,
    required bool snippetsEnabled,
    required List<String> tags,
  });

  Future<void> deleteTemplate(int id);

  Future<List<Map<String, dynamic>>> queryTemplates({
    int limit = 10,
    int offset = 0,
    List<String> tags = const [],
    String searchQuery = '',
    TemplateSortOption sortOption = TemplateSortOption.recentlyUpdated,
  });

  Future<void> updateTemplateTags(int templateId, List<String> tags);

  Future<void> setPinned(int id, bool pinned);

  Future<List<String>> queryAllTags();
  Future<List<(String name, int count)>> queryTagCounts();

  Future<void> savePreference(String key, String value);

  Future<String?> getPreference(String key);

  Future<void> cleanupOrphanedTags();
}
