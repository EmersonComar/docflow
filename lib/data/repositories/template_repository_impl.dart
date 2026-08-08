import '../../core/errors/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/template.dart';
import '../../domain/entities/template_sort_option.dart';
import '../../domain/repositories/template_repository.dart';
import '../datasources/local_database.dart';
import '../datasources/initial_data.dart';
import '../models/template_model.dart';

class TemplateRepositoryImpl implements TemplateRepository {
  final LocalDatabase _database;
  bool _initialized = false;

  TemplateRepositoryImpl(this._database);

  TemplateRepositoryImpl.preInitialized(this._database) : _initialized = true;

  @override
  Future<Result<void>> ensureInitialized() async {
    if (_initialized) return Result.success(null);

    try {
      await _database.initialize();
      
      final templates = await _database.queryTemplates(limit: 1);
      if (templates.isEmpty) {
        await createInitialData(_database);
      }
      
      _initialized = true;
      return Result.success(null);
    } catch (e) {
      return Result.failure(DatabaseFailure(
        'databaseInitializationFailed',
        [e.toString()],
        e,
      ));
    }
  }

  @override
  Future<Result<Template>> create(Template template) async {
    try {
      final model = TemplateModel.fromEntity(template);
      final id = await _database.createTemplateWithTags(model);

      return Result.success(template.copyWith(id: id));
    } catch (e) {
      return Result.failure(DatabaseFailure(
        'createTemplateFailed',
        [e.toString()],
        e,
      ));
    }
  }

  @override
  Future<Result<Template>> update(Template template) async {
    if (template.id == null) {
      return Result.failure(const ValidationFailure('templateIdCannotBeNull'));
    }

    try {
      final model = TemplateModel.fromEntity(template);
      await _database.updateTemplateWithTags(model);

      return Result.success(template);
    } catch (e) {
      return Result.failure(DatabaseFailure(
        'updateTemplateFailed',
        [e.toString()],
        e,
      ));
    }
  }

  @override
  Future<Result<void>> delete(int id) async {
    try {
      await _database.deleteTemplate(id);
      await _database.cleanupOrphanedTags();
      return Result.success(null);
    } catch (e) {
      return Result.failure(DatabaseFailure(
        'deleteTemplateFailed',
        [e.toString()],
        e,
      ));
    }
  }

  @override
  Future<Result<List<Template>>> getTemplates({
    int limit = 10,
    int offset = 0,
    List<String> tags = const [],
    String searchQuery = '',
    TemplateSortOption sortOption = TemplateSortOption.recentlyUpdated,
  }) async {
    try {
      final models = await _database.queryTemplates(
        limit: limit,
        offset: offset,
        tags: tags,
        searchQuery: searchQuery,
        sortOption: sortOption,
      );

      return Result.success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Result.failure(DatabaseFailure(
        'loadTemplatesFailed',
        [e.toString()],
        e,
      ));
    }
  }

  @override
  Future<Result<void>> setPinned(int id, bool pinned) async {
    try {
      await _database.setPinned(id, pinned);
      return Result.success(null);
    } catch (e) {
      return Result.failure(DatabaseFailure(
        'pinTemplateFailed',
        [e.toString()],
        e,
      ));
    }
  }

  @override
  Future<Result<List<String>>> getAllTags() async {
    try {
      final tags = await _database.queryAllTags();
      return Result.success(tags);
    } catch (e) {
      return Result.failure(DatabaseFailure(
        'loadTagsFailed',
        [e.toString()],
        e,
      ));
    }
  }

  @override
  Future<Result<List<(String name, int count)>>> getTagCounts() async {
    try {
      final counts = await _database.queryTagCounts();
      return Result.success(counts);
    } catch (e) {
      return Result.failure(DatabaseFailure(
        'loadTagsFailed',
        [e.toString()],
        e,
      ));
    }
  }
}