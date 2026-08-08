import 'database_driver.dart';

class MysqlDriver implements DatabaseDriver {
  MysqlDriver();

  MysqlDriver.inMemory();

  MysqlDriver.withConfig({
    required String host,
    required int port,
    required String database,
    required String username,
    required String password,
  });

  @override
  Future<void> initialize() async {
    throw UnimplementedError('MySQL support coming soon');
  }

  @override
  Future<void> close() async {
    throw UnimplementedError('MySQL support coming soon');
  }

  @override
  Future<int> insertTemplate({
    required String titulo,
    required String conteudo,
    required bool markdownEnabled,
    required bool snippetsEnabled,
  }) async {
    throw UnimplementedError('MySQL support coming soon');
  }

  @override
  Future<int> updateTemplate({
    required int id,
    required String titulo,
    required String conteudo,
    required bool markdownEnabled,
    required bool snippetsEnabled,
  }) async {
    throw UnimplementedError('MySQL support coming soon');
  }

  @override
  Future<int> createTemplateWithTags({
    required String titulo,
    required String conteudo,
    required bool markdownEnabled,
    required bool snippetsEnabled,
    required List<String> tags,
  }) async {
    throw UnimplementedError('MySQL support coming soon');
  }

  @override
  Future<void> updateTemplateWithTags({
    required int id,
    required String titulo,
    required String conteudo,
    required bool markdownEnabled,
    required bool snippetsEnabled,
    required List<String> tags,
  }) async {
    throw UnimplementedError('MySQL support coming soon');
  }

  @override
  Future<void> deleteTemplate(int id) async {
    throw UnimplementedError('MySQL support coming soon');
  }

  @override
  Future<List<Map<String, dynamic>>> queryTemplates({
    int limit = 10,
    int offset = 0,
    List<String> tags = const [],
    String searchQuery = '',
  }) async {
    throw UnimplementedError('MySQL support coming soon');
  }

  @override
  Future<void> updateTemplateTags(int templateId, List<String> tags) async {
    throw UnimplementedError('MySQL support coming soon');
  }

  @override
  Future<List<String>> queryAllTags() async {
    throw UnimplementedError('MySQL support coming soon');
  }

  @override
  Future<void> savePreference(String key, String value) async {
    throw UnimplementedError('MySQL support coming soon');
  }

  @override
  Future<String?> getPreference(String key) async {
    throw UnimplementedError('MySQL support coming soon');
  }

  @override
  Future<void> cleanupOrphanedTags() async {
    throw UnimplementedError('MySQL support coming soon');
  }
}
