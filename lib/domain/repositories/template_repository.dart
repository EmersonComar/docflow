import '../../core/utils/result.dart';
import '../entities/template.dart';
import '../entities/template_sort_option.dart';

abstract class TemplateRepository {
  Future<Result<Template>> create(Template template);
  Future<Result<Template>> update(Template template);
  Future<Result<void>> delete(int id);
  Future<Result<List<Template>>> getTemplates({
    int limit = 10,
    int offset = 0,
    List<String> tags = const [],
    String searchQuery = '',
    TemplateSortOption sortOption = TemplateSortOption.recentlyUpdated,
  });
  Future<Result<void>> setPinned(int id, bool pinned);
  Future<Result<List<String>>> getAllTags();
  Future<Result<List<(String name, int count)>>> getTagCounts();
  Future<Result<void>> ensureInitialized();
}
