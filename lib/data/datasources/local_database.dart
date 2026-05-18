import 'drivers/sqlite_drift_driver.dart';
import 'drivers/database_driver.dart';
import '../models/template_model.dart';

class LocalDatabase {
  late DatabaseDriver _driver;
  bool _initialized = false;

  LocalDatabase() {
    _driver = SqliteDriftDriver();
  }

  LocalDatabase.inMemory() {
    _driver = SqliteDriftDriver.inMemory();
  }

  LocalDatabase.withPath(String path) {
    _driver = SqliteDriftDriver.withPath(path);
  }

  LocalDatabase.withDriver(this._driver);

  Future<void> initialize() async {
    if (_initialized) return;
    await _driver.initialize();
    _initialized = true;
  }

  Future<int> insertTemplate(TemplateModel template) async {
    return await _driver.insertTemplate(
      titulo: template.titulo,
      conteudo: template.conteudo,
      markdownEnabled: template.markdownEnabled,
      snippetsEnabled: template.snippetsEnabled,
    );
  }

  Future<int> updateTemplate(TemplateModel template) async {
    if (template.id == null) throw StateError('Template id cannot be null');
    return await _driver.updateTemplate(
      id: template.id!,
      titulo: template.titulo,
      conteudo: template.conteudo,
      markdownEnabled: template.markdownEnabled,
      snippetsEnabled: template.snippetsEnabled,
    );
  }

  Future<void> deleteTemplate(int id) async {
    await _driver.deleteTemplate(id);
  }

  Future<void> updateTemplateTags(int templateId, List<String> tags) async {
    await _driver.updateTemplateTags(templateId, tags);
  }

  Future<void> cleanupOrphanedTags() async {
    await _driver.cleanupOrphanedTags();
  }

  Future<List<TemplateModel>> queryTemplates({
    int limit = 10,
    int offset = 0,
    List<String> tags = const [],
    String searchQuery = '',
  }) async {
    final results = await _driver.queryTemplates(
      limit: limit,
      offset: offset,
      tags: tags,
      searchQuery: searchQuery,
    );
    return results.map((map) => TemplateModel.fromMap(map)).toList();
  }

  Future<List<String>> queryAllTags() async {
    return await _driver.queryAllTags();
  }

  Future<void> savePreference(String key, String value) async {
    await _driver.savePreference(key, value);
  }

  Future<String?> getPreference(String key) async {
    return await _driver.getPreference(key);
  }

  Future<void> close() async {
    await _driver.close();
    _initialized = false;
  }
}