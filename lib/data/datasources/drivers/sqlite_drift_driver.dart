import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'database_driver.dart';

class SqliteDriftDriver implements DatabaseDriver {
  Database? _database;
  final bool _inMemory;
  final String? _customPath;

  SqliteDriftDriver()
      : _inMemory = false,
        _customPath = null;

  SqliteDriftDriver.inMemory()
      : _inMemory = true,
        _customPath = null;

  SqliteDriftDriver.withPath(String path)
      : _inMemory = false,
        _customPath = path;

  @override
  Future<void> initialize() async {
    if (_database != null) return;

    if (_inMemory) {
      _database = await openDatabase(
        inMemoryDatabasePath,
        version: 3,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
      return;
    }

    final String path;
    if (_customPath != null) {
      path = _customPath;
    } else {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      path = join(documentsDirectory.path, 'templates.db');
    }

    _database = await openDatabase(
      path,
      version: 3,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
    await db.execute('PRAGMA journal_mode = DELETE');
    await db.execute('PRAGMA synchronous = FULL');
    await db.execute('PRAGMA cache_size = 5000');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS templates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        conteudo TEXT NOT NULL,
        markdown_enabled INTEGER NOT NULL DEFAULT 1,
        snippets_enabled INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS template_tags (
        template_id INTEGER NOT NULL,
        tag_id INTEGER NOT NULL,
        PRIMARY KEY (template_id, tag_id),
        FOREIGN KEY (template_id) REFERENCES templates (id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_preferences (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_template_tags_template ON template_tags(template_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_template_tags_tag ON template_tags(tag_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tags_name ON tags(name)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_template_tags_template ON template_tags(template_id)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_template_tags_tag ON template_tags(tag_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_tags_name ON tags(name)');
    }

    if (oldVersion < 3) {
      await db.execute(
          'ALTER TABLE templates ADD COLUMN markdown_enabled INTEGER NOT NULL DEFAULT 1');
      await db.execute(
          'ALTER TABLE templates ADD COLUMN snippets_enabled INTEGER NOT NULL DEFAULT 1');
    }
  }

  Database get db {
    if (_database == null) throw StateError('Database not initialized');
    return _database!;
  }

  @override
  Future<int> insertTemplate({
    required String titulo,
    required String conteudo,
    required bool markdownEnabled,
    required bool snippetsEnabled,
  }) async {
    return await db.insert('templates', {
      'titulo': titulo,
      'conteudo': conteudo,
      'markdown_enabled': markdownEnabled ? 1 : 0,
      'snippets_enabled': snippetsEnabled ? 1 : 0,
    });
  }

  @override
  Future<int> updateTemplate({
    required int id,
    required String titulo,
    required String conteudo,
    required bool markdownEnabled,
    required bool snippetsEnabled,
  }) async {
    return await db.update(
      'templates',
      {
        'titulo': titulo,
        'conteudo': conteudo,
        'markdown_enabled': markdownEnabled ? 1 : 0,
        'snippets_enabled': snippetsEnabled ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteTemplate(int id) async {
    await db.delete('templates', where: 'id = ?', whereArgs: [id]);
    await cleanupOrphanedTags();
  }

  @override
  Future<List<Map<String, dynamic>>> queryTemplates({
    int limit = 10,
    int offset = 0,
    List<String> tags = const [],
    String searchQuery = '',
  }) async {
    final buffer = StringBuffer('''
      SELECT t.id, t.titulo, t.conteudo, t.markdown_enabled, t.snippets_enabled, GROUP_CONCAT(tg.name) as tags
      FROM templates t
      LEFT JOIN template_tags tt ON t.id = tt.template_id
      LEFT JOIN tags tg ON tt.tag_id = tg.id
    ''');

    final params = <dynamic>[];
    final whereClauses = <String>[];

    if (tags.isNotEmpty) {
      whereClauses.add('''
        t.id IN (
          SELECT tt.template_id
          FROM template_tags tt
          JOIN tags tg ON tt.tag_id = tg.id
          WHERE tg.name IN (${tags.map((_) => '?').join(',')})
        )
      ''');
      params.addAll(tags);
    }

    if (searchQuery.isNotEmpty) {
      whereClauses.add('(t.titulo LIKE ? OR t.conteudo LIKE ?)');
      params.add('%$searchQuery%');
      params.add('%$searchQuery%');
    }

    if (whereClauses.isNotEmpty) {
      buffer.write(' WHERE ${whereClauses.join(' AND ')}');
    }

    buffer.write(' GROUP BY t.id ORDER BY t.id DESC LIMIT ? OFFSET ?');
    params.add(limit);
    params.add(offset);

    final result = await db.rawQuery(buffer.toString(), params);
    return result;
  }

  @override
  Future<void> updateTemplateTags(int templateId, List<String> tags) async {
    await db.delete('template_tags',
        where: 'template_id = ?', whereArgs: [templateId]);

    for (final tagName in tags) {
      final trimmed = tagName.trim();
      if (trimmed.isEmpty) continue;

      int tagId;
      final existing = await db.query('tags', where: 'name = ?', whereArgs: [trimmed]);

      if (existing.isNotEmpty) {
        tagId = existing.first['id'] as int;
      } else {
        tagId = await db.insert('tags', {'name': trimmed});
      }

      await db.insert('template_tags',
          {'template_id': templateId, 'tag_id': tagId});
    }

    await cleanupOrphanedTags();
  }

  @override
  Future<List<String>> queryAllTags() async {
    final result =
        await db.query('tags', columns: ['name'], orderBy: 'name ASC');
    return result.map((map) => map['name'] as String).toList();
  }

  @override
  Future<void> savePreference(String key, String value) async {
    await db.insert(
      'user_preferences',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<String?> getPreference(String key) async {
    final result =
        await db.query('user_preferences', where: 'key = ?', whereArgs: [key]);
    return result.isNotEmpty ? result.first['value'] as String? : null;
  }

  @override
  Future<void> cleanupOrphanedTags() async {
    await db.rawDelete('''
      DELETE FROM tags
      WHERE NOT EXISTS (
        SELECT 1 
        FROM template_tags tt 
        WHERE tt.tag_id = tags.id
      )
    ''');
  }

  @override
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
