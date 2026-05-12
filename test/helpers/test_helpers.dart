import 'package:docflow/data/datasources/local_database.dart';
import 'package:docflow/domain/entities/template.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Initializes sqflite_common_ffi for unit/integration tests.
/// Call once in setUpAll.
void initTestDatabase() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

/// Creates and initializes an in-memory [LocalDatabase] for testing.
/// Does NOT seed initial data, giving tests a clean empty state.
Future<LocalDatabase> createInMemoryDatabase() async {
  final db = LocalDatabase.inMemory();
  await db.initialize();
  return db;
}

/// Returns a valid [Template] for use in tests.
Template makeTemplate({
  int? id,
  String titulo = 'Template de Teste',
  String conteudo = 'Conteúdo de {{variavel}}.',
  List<String> tags = const ['tag1', 'tag2'],
  bool markdownEnabled = true,
  bool snippetsEnabled = true,
}) {
  return Template(
    id: id,
    titulo: titulo,
    conteudo: conteudo,
    tags: tags,
    markdownEnabled: markdownEnabled,
    snippetsEnabled: snippetsEnabled,
  );
}
