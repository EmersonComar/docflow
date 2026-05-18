import 'package:postgres/postgres.dart';
import '../../models/postgres_credentials.dart';
import 'database_driver.dart';

class PostgresDriver implements DatabaseDriver {
  late Connection _connection;
  final PostgresCredentials _credentials;
  bool _initialized = false;

  PostgresDriver() : this.inMemory();

  PostgresDriver.inMemory()
      : _credentials = const PostgresCredentials(
          host: 'localhost',
          port: 5432,
          database: 'docflow_test',
          username: 'postgres',
          password: 'postgres',
        );

  PostgresDriver.withConfig({
    required String host,
    required int port,
    required String database,
    required String username,
    required String password,
  }) : _credentials = PostgresCredentials(
    host: host,
    port: port,
    database: database,
    username: username,
    password: password,
  );

  @override
  Future<void> initialize() async {
    try {
      _connection = await Connection.open(
        Endpoint(
          host: _credentials.host,
          port: _credentials.port,
          database: _credentials.database,
          username: _credentials.username,
          password: _credentials.password,
        ),
        settings: const ConnectionSettings(
          sslMode: SslMode.disable,
        ),
      );

      await _setupSchema();
      _initialized = true;
    } catch (e) {
      throw Exception('Failed to connect to PostgreSQL: $e');
    }
  }

  Future<void> _setupSchema() async {
    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS templates (
        id SERIAL PRIMARY KEY,
        titulo TEXT NOT NULL,
        conteudo TEXT NOT NULL,
        markdown_enabled BOOLEAN NOT NULL DEFAULT true,
        snippets_enabled BOOLEAN NOT NULL DEFAULT true
      )
    ''');

    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS tags (
        id SERIAL PRIMARY KEY,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS template_tags (
        template_id INTEGER NOT NULL,
        tag_id INTEGER NOT NULL,
        PRIMARY KEY (template_id, tag_id),
        FOREIGN KEY (template_id) REFERENCES templates (id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE
      )
    ''');

    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS user_preferences (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_template_tags_template ON template_tags(template_id)
    ''');

    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_template_tags_tag ON template_tags(tag_id)
    ''');

    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_tags_name ON tags(name)
    ''');
  }

  @override
  Future<int> insertTemplate({
    required String titulo,
    required String conteudo,
    required bool markdownEnabled,
    required bool snippetsEnabled,
  }) async {
    final result = await _connection.execute(
      Sql.named(
        'INSERT INTO templates (titulo, conteudo, markdown_enabled, snippets_enabled) '
        'VALUES (@titulo, @conteudo, @markdown, @snippets) RETURNING id',
      ),
      parameters: {
        'titulo': titulo,
        'conteudo': conteudo,
        'markdown': markdownEnabled,
        'snippets': snippetsEnabled,
      },
    );

    return result.first.toColumnMap()['id'] as int;
  }

  @override
  Future<int> updateTemplate({
    required int id,
    required String titulo,
    required String conteudo,
    required bool markdownEnabled,
    required bool snippetsEnabled,
  }) async {
    await _connection.execute(
      Sql.named(
        'UPDATE templates SET titulo = @titulo, conteudo = @conteudo, '
        'markdown_enabled = @markdown, snippets_enabled = @snippets '
        'WHERE id = @id',
      ),
      parameters: {
        'id': id,
        'titulo': titulo,
        'conteudo': conteudo,
        'markdown': markdownEnabled,
        'snippets': snippetsEnabled,
      },
    );

    return id;
  }

  @override
  Future<void> deleteTemplate(int id) async {
    await _connection.execute(
      Sql.named('DELETE FROM templates WHERE id = @id'),
      parameters: {'id': id},
    );
    await cleanupOrphanedTags();
  }

  @override
  Future<List<Map<String, dynamic>>> queryTemplates({
    int limit = 10,
    int offset = 0,
    List<String> tags = const [],
    String searchQuery = '',
  }) async {
    final buffer = StringBuffer(
      'SELECT t.id, t.titulo, t.conteudo, t.markdown_enabled, t.snippets_enabled, '
      'STRING_AGG(tg.name, \',\') as tags '
      'FROM templates t '
      'LEFT JOIN template_tags tt ON t.id = tt.template_id '
      'LEFT JOIN tags tg ON tt.tag_id = tg.id ',
    );

    final params = <String, dynamic>{};
    final whereClauses = <String>[];

    if (tags.isNotEmpty) {
      whereClauses.add(
        't.id IN (SELECT tt.template_id FROM template_tags tt '
        'JOIN tags tg ON tt.tag_id = tg.id WHERE tg.name = ANY(@tags))',
      );
      params['tags'] = tags;
    }

    if (searchQuery.isNotEmpty) {
      whereClauses.add(
        '(t.titulo ILIKE @search OR t.conteudo ILIKE @search)',
      );
      params['search'] = '%$searchQuery%';
    }

    if (whereClauses.isNotEmpty) {
      buffer.write(' WHERE ${whereClauses.join(' AND ')}');
    }

    buffer.write(' GROUP BY t.id ORDER BY t.id DESC LIMIT @limit OFFSET @offset');
    params['limit'] = limit;
    params['offset'] = offset;

    final results = await _connection.execute(
      Sql.named(buffer.toString()),
      parameters: params,
    );

    return results
        .map((row) => Map<String, dynamic>.from(row.toColumnMap()))
        .toList();
  }

  @override
  Future<void> updateTemplateTags(int templateId, List<String> tags) async {
    await _connection.execute(
      Sql.named('DELETE FROM template_tags WHERE template_id = @templateId'),
      parameters: {'templateId': templateId},
    );

    for (final tagName in tags) {
      final trimmed = tagName.trim();
      if (trimmed.isEmpty) continue;

      final existing = await _connection.execute(
        Sql.named('SELECT id FROM tags WHERE name = @name'),
        parameters: {'name': trimmed},
      );

      int tagId;
      if (existing.isNotEmpty) {
        tagId = existing.first.toColumnMap()['id'] as int;
      } else {
        final insertResult = await _connection.execute(
          Sql.named('INSERT INTO tags (name) VALUES (@name) RETURNING id'),
          parameters: {'name': trimmed},
        );
        tagId = insertResult.first.toColumnMap()['id'] as int;
      }

      await _connection.execute(
        Sql.named(
          'INSERT INTO template_tags (template_id, tag_id) '
          'VALUES (@templateId, @tagId)',
        ),
        parameters: {
          'templateId': templateId,
          'tagId': tagId,
        },
      );
    }

    await cleanupOrphanedTags();
  }

  @override
  Future<List<String>> queryAllTags() async {
    final results = await _connection.execute(
      'SELECT name FROM tags ORDER BY name ASC',
    );

    return results
        .map((row) => row.toColumnMap()['name'] as String)
        .toList();
  }

  @override
  Future<void> savePreference(String key, String value) async {
    await _connection.execute(
      Sql.named(
        'INSERT INTO user_preferences (key, value) VALUES (@key, @value) '
        'ON CONFLICT (key) DO UPDATE SET value = @value',
      ),
      parameters: {
        'key': key,
        'value': value,
      },
    );
  }

  @override
  Future<String?> getPreference(String key) async {
    final result = await _connection.execute(
      Sql.named('SELECT value FROM user_preferences WHERE key = @key'),
      parameters: {'key': key},
    );

    return result.isNotEmpty
        ? result.first.toColumnMap()['value'] as String?
        : null;
  }

  @override
  Future<void> cleanupOrphanedTags() async {
    await _connection.execute(
      'DELETE FROM tags WHERE NOT EXISTS '
      '(SELECT 1 FROM template_tags tt WHERE tt.tag_id = tags.id)',
    );
  }

  @override
  Future<void> close() async {
    if (_initialized) {
      await _connection.close();
      _initialized = false;
    }
  }
}

