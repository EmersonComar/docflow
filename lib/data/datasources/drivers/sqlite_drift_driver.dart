import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../../../domain/entities/template_sort_option.dart';
import 'database_driver.dart';

class SqliteDriftDriver implements DatabaseDriver {
  Database? _database;
  final bool _inMemory;
  final String? _customPath;

  static const _schemaVersion = 4;

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
        version: _schemaVersion,
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
      version: _schemaVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
    await db.execute('PRAGMA journal_mode = WAL');
    await db.execute('PRAGMA synchronous = NORMAL');
    await db.execute('PRAGMA cache_size = 5000');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS templates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        conteudo TEXT NOT NULL,
        markdown_enabled INTEGER NOT NULL DEFAULT 1,
        snippets_enabled INTEGER NOT NULL DEFAULT 1,
        updated_at TEXT NOT NULL,
        pinned INTEGER NOT NULL DEFAULT 0
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

    await _createFtsSchema(db);
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
      await _addColumnIfMissing(
          db, 'templates', 'markdown_enabled', 'INTEGER NOT NULL DEFAULT 1');
      await _addColumnIfMissing(
          db, 'templates', 'snippets_enabled', 'INTEGER NOT NULL DEFAULT 1');
    }

    if (oldVersion < 4) {
      await _addColumnIfMissing(db, 'templates', 'updated_at', 'TEXT');
      await _addColumnIfMissing(
          db, 'templates', 'pinned', 'INTEGER NOT NULL DEFAULT 0');

      final now = DateTime.now().toUtc().toIso8601String();
      await db.update(
        'templates',
        {'updated_at': now},
        where: 'updated_at IS NULL',
      );

      await _createFtsSchema(db);
      await db.execute("INSERT INTO templates_fts(templates_fts) VALUES('rebuild')");
    }
  }

  Future<bool> _columnExists(Database db, String table, String column) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    return columns.any((row) => row['name'] == column);
  }

  Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    if (await _columnExists(db, table, column)) return;
    await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
  }

  Future<void> _createFtsSchema(Database db) async {
    await db.execute('''
      CREATE VIRTUAL TABLE IF NOT EXISTS templates_fts USING fts5(
        titulo, conteudo, content='templates', content_rowid='id'
      )
    ''');

    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS templates_ai AFTER INSERT ON templates BEGIN
        INSERT INTO templates_fts(rowid, titulo, conteudo) VALUES (new.id, new.titulo, new.conteudo);
      END
    ''');

    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS templates_ad AFTER DELETE ON templates BEGIN
        INSERT INTO templates_fts(templates_fts, rowid, titulo, conteudo)
        VALUES('delete', old.id, old.titulo, old.conteudo);
      END
    ''');

    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS templates_au AFTER UPDATE ON templates BEGIN
        INSERT INTO templates_fts(templates_fts, rowid, titulo, conteudo)
        VALUES('delete', old.id, old.titulo, old.conteudo);
        INSERT INTO templates_fts(rowid, titulo, conteudo) VALUES (new.id, new.titulo, new.conteudo);
      END
    ''');
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
      'updated_at': _now(),
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
        'updated_at': _now(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<int> createTemplateWithTags({
    required String titulo,
    required String conteudo,
    required bool markdownEnabled,
    required bool snippetsEnabled,
    required List<String> tags,
  }) async {
    return db.transaction((txn) async {
      final id = await txn.insert('templates', {
        'titulo': titulo,
        'conteudo': conteudo,
        'markdown_enabled': markdownEnabled ? 1 : 0,
        'snippets_enabled': snippetsEnabled ? 1 : 0,
        'updated_at': _now(),
      });
      await _syncTags(txn, id, tags);
      await _cleanupOrphanedTags(txn);
      return id;
    });
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
    await db.transaction((txn) async {
      await txn.update(
        'templates',
        {
          'titulo': titulo,
          'conteudo': conteudo,
          'markdown_enabled': markdownEnabled ? 1 : 0,
          'snippets_enabled': snippetsEnabled ? 1 : 0,
          'updated_at': _now(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      await _syncTags(txn, id, tags);
      await _cleanupOrphanedTags(txn);
    });
  }

  @override
  Future<void> deleteTemplate(int id) async {
    await db.delete('templates', where: 'id = ?', whereArgs: [id]);
    await cleanupOrphanedTags();
  }

  @override
  Future<void> setPinned(int id, bool pinned) async {
    await db.update(
      'templates',
      {'pinned': pinned ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<Map<String, dynamic>>> queryTemplates({
    int limit = 10,
    int offset = 0,
    List<String> tags = const [],
    String searchQuery = '',
    TemplateSortOption sortOption = TemplateSortOption.recentlyUpdated,
  }) async {
    final ftsQuery = _buildFtsMatchQuery(searchQuery);

    final buffer = StringBuffer();
    final params = <dynamic>[];

    if (ftsQuery != null) {
      buffer.write('''
        WITH matches AS MATERIALIZED (
          SELECT templates_fts.rowid AS id, bm25(templates_fts) AS rank
          FROM templates_fts
          WHERE templates_fts MATCH ?
        )
        SELECT t.id, t.titulo, t.conteudo, t.markdown_enabled, t.snippets_enabled,
               t.pinned, t.updated_at, GROUP_CONCAT(tg.name) as tags
        FROM matches m
        JOIN templates t ON t.id = m.id
      ''');
      params.add(ftsQuery);
    } else {
      buffer.write('''
        SELECT t.id, t.titulo, t.conteudo, t.markdown_enabled, t.snippets_enabled,
               t.pinned, t.updated_at, GROUP_CONCAT(tg.name) as tags
        FROM templates t
      ''');
    }

    buffer.write('''
      LEFT JOIN template_tags tt ON t.id = tt.template_id
      LEFT JOIN tags tg ON tt.tag_id = tg.id
    ''');

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

    if (whereClauses.isNotEmpty) {
      buffer.write(' WHERE ${whereClauses.join(' AND ')}');
    }

    buffer.write(' GROUP BY t.id ORDER BY t.pinned DESC, ');
    if (ftsQuery != null) {
      buffer.write('MIN(m.rank) ASC, ');
    } else {
      switch (sortOption) {
        case TemplateSortOption.recentlyUpdated:
          buffer.write('t.updated_at DESC, ');
        case TemplateSortOption.recentlyCreated:
          break; 
        case TemplateSortOption.titleAsc:
          buffer.write('LOWER(t.titulo) ASC, ');
      }
    }
    buffer.write('t.id DESC LIMIT ? OFFSET ?');
    params.add(limit);
    params.add(offset);

    final result = await db.rawQuery(buffer.toString(), params);
    return result;
  }

  static String? _buildFtsMatchQuery(String raw) {
    final tokens = raw
        .split(RegExp(r'\s+'))
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return null;

    return tokens.map((t) {
      final escaped = t.replaceAll('"', '""');
      return '"$escaped"*';
    }).join(' ');
  }

  static String _now() => DateTime.now().toUtc().toIso8601String();

  @override
  Future<void> updateTemplateTags(int templateId, List<String> tags) async {
    await _syncTags(db, templateId, tags);
    await cleanupOrphanedTags();
  }

  Future<void> _syncTags(
    DatabaseExecutor executor,
    int templateId,
    List<String> tags,
  ) async {
    await executor.delete('template_tags',
        where: 'template_id = ?', whereArgs: [templateId]);

    for (final tagName in tags) {
      final trimmed = tagName.trim();
      if (trimmed.isEmpty) continue;

      int tagId;
      final existing = await executor.query(
        'tags',
        where: 'LOWER(name) = LOWER(?)',
        whereArgs: [trimmed],
      );

      if (existing.isNotEmpty) {
        tagId = existing.first['id'] as int;
      } else {
        tagId = await executor.insert('tags', {'name': trimmed});
      }

      await executor.insert('template_tags',
          {'template_id': templateId, 'tag_id': tagId});
    }
  }

  @override
  Future<List<String>> queryAllTags() async {
    final result =
        await db.query('tags', columns: ['name'], orderBy: 'name ASC');
    return result.map((map) => map['name'] as String).toList();
  }

  @override
  Future<List<(String name, int count)>> queryTagCounts() async {
    final result = await db.rawQuery('''
      SELECT tg.name as name, COUNT(tt.template_id) as count
      FROM tags tg
      LEFT JOIN template_tags tt ON tt.tag_id = tg.id
      GROUP BY tg.id
      ORDER BY count DESC, tg.name ASC
    ''');
    return result.map((row) => (row['name'] as String, row['count'] as int)).toList();
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
    await _cleanupOrphanedTags(db);
  }

  Future<void> _cleanupOrphanedTags(DatabaseExecutor executor) async {
    await executor.rawDelete('''
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
