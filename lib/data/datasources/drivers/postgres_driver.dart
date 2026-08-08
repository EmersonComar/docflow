import 'dart:convert';
import 'dart:io';
import 'package:postgres/postgres.dart';
import '../../../domain/entities/template_sort_option.dart';
import '../../models/postgres_credentials.dart';
import 'database_driver.dart';

class PostgresDriver implements DatabaseDriver {
  Connection? _connection;
  final PostgresCredentials _credentials;
  bool _initialized = false;

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
    bool sslEnabled = false,
    String? caCertificatePem,
  }) : _credentials = PostgresCredentials(
    host: host,
    port: port,
    database: database,
    username: username,
    password: password,
    sslEnabled: sslEnabled,
    caCertificatePem: caCertificatePem,
  );

  Connection get _conn {
    final connection = _connection;
    if (connection == null) {
      throw StateError('PostgresDriver not initialized. Call initialize() first.');
    }
    return connection;
  }

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    Connection? connection;
    try {
      connection = await Connection.open(
        Endpoint(
          host: _credentials.host,
          port: _credentials.port,
          database: _credentials.database,
          username: _credentials.username,
          password: _credentials.password,
        ),
        settings: ConnectionSettings(
          sslMode: _credentials.sslEnabled ? SslMode.verifyFull : SslMode.disable,
          securityContext: buildSecurityContext(_credentials.caCertificatePem),
        ),
      );
      _connection = connection;

      await _setupSchema();
      _initialized = true;
    } catch (e) {
      await connection?.close();
      _connection = null;
      throw Exception('Failed to connect to PostgreSQL: $e');
    }
  }

  Future<void> _setupSchema() async {
    await _conn.execute('''
      CREATE TABLE IF NOT EXISTS templates (
        id SERIAL PRIMARY KEY,
        titulo TEXT NOT NULL,
        conteudo TEXT NOT NULL,
        markdown_enabled BOOLEAN NOT NULL DEFAULT true,
        snippets_enabled BOOLEAN NOT NULL DEFAULT true
      )
    ''');

    await _conn.execute('''
      CREATE TABLE IF NOT EXISTS tags (
        id SERIAL PRIMARY KEY,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    await _conn.execute('''
      CREATE TABLE IF NOT EXISTS template_tags (
        template_id INTEGER NOT NULL,
        tag_id INTEGER NOT NULL,
        PRIMARY KEY (template_id, tag_id),
        FOREIGN KEY (template_id) REFERENCES templates (id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE
      )
    ''');

    await _conn.execute('''
      CREATE TABLE IF NOT EXISTS user_preferences (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await _conn.execute('''
      CREATE INDEX IF NOT EXISTS idx_template_tags_template ON template_tags(template_id)
    ''');

    await _conn.execute('''
      CREATE INDEX IF NOT EXISTS idx_template_tags_tag ON template_tags(tag_id)
    ''');

    await _conn.execute('''
      CREATE INDEX IF NOT EXISTS idx_tags_name ON tags(name)
    ''');

    await _conn.execute('''
      ALTER TABLE templates ADD COLUMN IF NOT EXISTS updated_at TEXT
    ''');
    await _conn.execute('''
      ALTER TABLE templates ADD COLUMN IF NOT EXISTS pinned BOOLEAN NOT NULL DEFAULT false
    ''');
    await _conn.execute(
      Sql.named('UPDATE templates SET updated_at = @now WHERE updated_at IS NULL'),
      parameters: {'now': _now()},
    );

    await _conn.execute('''
      ALTER TABLE templates ADD COLUMN IF NOT EXISTS search_vector tsvector
        GENERATED ALWAYS AS (to_tsvector('simple', coalesce(titulo, '') || ' ' || coalesce(conteudo, ''))) STORED
    ''');
    await _conn.execute('''
      CREATE INDEX IF NOT EXISTS idx_templates_search ON templates USING GIN(search_vector)
    ''');
  }

  @override
  Future<int> insertTemplate({
    required String titulo,
    required String conteudo,
    required bool markdownEnabled,
    required bool snippetsEnabled,
  }) async {
    final result = await _conn.execute(
      Sql.named(
        'INSERT INTO templates (titulo, conteudo, markdown_enabled, snippets_enabled, updated_at) '
        'VALUES (@titulo, @conteudo, @markdown, @snippets, @updatedAt) RETURNING id',
      ),
      parameters: {
        'titulo': titulo,
        'conteudo': conteudo,
        'markdown': markdownEnabled,
        'snippets': snippetsEnabled,
        'updatedAt': _now(),
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
    await _conn.execute(
      Sql.named(
        'UPDATE templates SET titulo = @titulo, conteudo = @conteudo, '
        'markdown_enabled = @markdown, snippets_enabled = @snippets, updated_at = @updatedAt '
        'WHERE id = @id',
      ),
      parameters: {
        'id': id,
        'titulo': titulo,
        'conteudo': conteudo,
        'markdown': markdownEnabled,
        'snippets': snippetsEnabled,
        'updatedAt': _now(),
      },
    );

    return id;
  }

  @override
  Future<int> createTemplateWithTags({
    required String titulo,
    required String conteudo,
    required bool markdownEnabled,
    required bool snippetsEnabled,
    required List<String> tags,
  }) async {
    return _conn.runTx((session) async {
      final result = await session.execute(
        Sql.named(
          'INSERT INTO templates (titulo, conteudo, markdown_enabled, snippets_enabled, updated_at) '
          'VALUES (@titulo, @conteudo, @markdown, @snippets, @updatedAt) RETURNING id',
        ),
        parameters: {
          'titulo': titulo,
          'conteudo': conteudo,
          'markdown': markdownEnabled,
          'snippets': snippetsEnabled,
          'updatedAt': _now(),
        },
      );
      final id = result.first.toColumnMap()['id'] as int;

      await _syncTags(session, id, tags);
      await _cleanupOrphanedTags(session);
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
    await _conn.runTx((session) async {
      await session.execute(
        Sql.named(
          'UPDATE templates SET titulo = @titulo, conteudo = @conteudo, '
          'markdown_enabled = @markdown, snippets_enabled = @snippets, updated_at = @updatedAt '
          'WHERE id = @id',
        ),
        parameters: {
          'id': id,
          'titulo': titulo,
          'conteudo': conteudo,
          'markdown': markdownEnabled,
          'snippets': snippetsEnabled,
          'updatedAt': _now(),
        },
      );

      await _syncTags(session, id, tags);
      await _cleanupOrphanedTags(session);
    });
  }

  @override
  Future<void> setPinned(int id, bool pinned) async {
    await _conn.execute(
      Sql.named('UPDATE templates SET pinned = @pinned WHERE id = @id'),
      parameters: {'id': id, 'pinned': pinned},
    );
  }

  static String _now() => DateTime.now().toUtc().toIso8601String();

  @override
  Future<void> deleteTemplate(int id) async {
    await _conn.execute(
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
    TemplateSortOption sortOption = TemplateSortOption.recentlyUpdated,
  }) async {
    final hasSearch = searchQuery.trim().isNotEmpty;

    final buffer = StringBuffer(
      'SELECT t.id, t.titulo, t.conteudo, t.markdown_enabled, t.snippets_enabled, '
      't.pinned, t.updated_at, '
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

    if (hasSearch) {
      whereClauses.add(
        "t.search_vector @@ websearch_to_tsquery('simple', @search)",
      );
      params['search'] = searchQuery;
    }

    if (whereClauses.isNotEmpty) {
      buffer.write(' WHERE ${whereClauses.join(' AND ')}');
    }

    buffer.write(' GROUP BY t.id ORDER BY t.pinned DESC, ');
    if (hasSearch) {
      buffer.write(
        "ts_rank(t.search_vector, websearch_to_tsquery('simple', @search)) DESC, ",
      );
    } else {
      switch (sortOption) {
        case TemplateSortOption.recentlyUpdated:
          buffer.write('t.updated_at DESC, ');
        case TemplateSortOption.recentlyCreated:
          break; // t.id DESC abaixo já resolve
        case TemplateSortOption.titleAsc:
          buffer.write('LOWER(t.titulo) ASC, ');
      }
    }
    buffer.write('t.id DESC LIMIT @limit OFFSET @offset');
    params['limit'] = limit;
    params['offset'] = offset;

    final results = await _conn.execute(
      Sql.named(buffer.toString()),
      parameters: params,
    );

    return results
        .map((row) => Map<String, dynamic>.from(row.toColumnMap()))
        .toList();
  }

  @override
  Future<void> updateTemplateTags(int templateId, List<String> tags) async {
    await _conn.runTx((session) async {
      await _syncTags(session, templateId, tags);
      await _cleanupOrphanedTags(session);
    });
  }

  Future<void> _syncTags(Session session, int templateId, List<String> tags) async {
    final seenLower = <String>{};
    final trimmedTags = <String>[];
    for (final raw in tags.map((t) => t.trim()).where((t) => t.isNotEmpty)) {
      if (seenLower.add(raw.toLowerCase())) trimmedTags.add(raw);
    }

    await session.execute(
      Sql.named('DELETE FROM template_tags WHERE template_id = @templateId'),
      parameters: {'templateId': templateId},
    );

    if (trimmedTags.isEmpty) return;

    final lowerNames = trimmedTags.map((t) => t.toLowerCase()).toList();

    final existingRows = await session.execute(
      Sql.named('SELECT id, name FROM tags WHERE LOWER(name) = ANY(@lowerNames::text[])'),
      parameters: {'lowerNames': lowerNames},
    );
    final existingLower = existingRows
        .map((row) => (row.toColumnMap()['name'] as String).toLowerCase())
        .toSet();

    final namesToInsert =
        trimmedTags.where((t) => !existingLower.contains(t.toLowerCase())).toList();

    if (namesToInsert.isNotEmpty) {
      await session.execute(
        Sql.named(
          'INSERT INTO tags (name) SELECT UNNEST(@names::text[]) '
          'ON CONFLICT (name) DO NOTHING',
        ),
        parameters: {'names': namesToInsert},
      );
    }

    final tagRows = await session.execute(
      Sql.named('SELECT id FROM tags WHERE LOWER(name) = ANY(@lowerNames::text[])'),
      parameters: {'lowerNames': lowerNames},
    );
    final tagIds = tagRows.map((row) => row.toColumnMap()['id'] as int).toSet().toList();

    if (tagIds.isEmpty) return;

    await session.execute(
      Sql.named(
        'INSERT INTO template_tags (template_id, tag_id) '
        'SELECT @templateId, UNNEST(@tagIds::int[]) '
        'ON CONFLICT DO NOTHING',
      ),
      parameters: {'templateId': templateId, 'tagIds': tagIds},
    );
  }

  @override
  Future<List<String>> queryAllTags() async {
    final results = await _conn.execute(
      'SELECT name FROM tags ORDER BY name ASC',
    );

    return results
        .map((row) => row.toColumnMap()['name'] as String)
        .toList();
  }

  @override
  Future<List<(String name, int count)>> queryTagCounts() async {
    final results = await _conn.execute('''
      SELECT tg.name as name, COUNT(tt.template_id) as count
      FROM tags tg
      LEFT JOIN template_tags tt ON tt.tag_id = tg.id
      GROUP BY tg.id
      ORDER BY count DESC, tg.name ASC
    ''');

    return results
        .map((row) => row.toColumnMap())
        .map((row) => (row['name'] as String, (row['count'] as int)))
        .toList();
  }

  @override
  Future<void> savePreference(String key, String value) async {
    await _conn.execute(
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
    final result = await _conn.execute(
      Sql.named('SELECT value FROM user_preferences WHERE key = @key'),
      parameters: {'key': key},
    );

    return result.isNotEmpty
        ? result.first.toColumnMap()['value'] as String?
        : null;
  }

  @override
  Future<void> cleanupOrphanedTags() async {
    await _cleanupOrphanedTags(_conn);
  }

  Future<void> _cleanupOrphanedTags(Session session) async {
    await session.execute(
      'DELETE FROM tags WHERE NOT EXISTS '
      '(SELECT 1 FROM template_tags tt WHERE tt.tag_id = tags.id)',
    );
  }

  @override
  Future<void> close() async {
    final connection = _connection;
    _initialized = false;
    _connection = null;
    if (connection != null) {
      await connection.close();
    }
  }
}

/// Constrói o [SecurityContext] usado na conexão TLS, quando o usuário
/// forneceu um certificado (PEM) de um servidor com certificado
/// autoassinado — ou `null` para usar o trust store padrão do sistema
/// (caso normal de certificado emitido por uma CA pública).
///
/// Importante: [SecurityContext] é criado com `withTrustedRoots: false`
/// (o padrão da própria API), então quando [caCertificatePem] é fornecido,
/// a conexão passa a confiar *apenas* nesse certificado — não nas CAs
/// públicas do sistema. É mais restritivo que `SslMode.require` (que
/// aceita qualquer certificado) e ainda mais restritivo que confiar em
/// todas as CAs públicas: só o certificado exato que o usuário selecionou
/// é aceito, o que segue sendo eficaz contra man-in-the-middle mesmo sem
/// uma CA real por trás.
///
/// Lança [TlsException] se [caCertificatePem] não for um certificado PEM
/// válido — o chamador ([initialize]) propaga isso como erro de conexão.
SecurityContext? buildSecurityContext(String? caCertificatePem) {
  if (caCertificatePem == null || caCertificatePem.trim().isEmpty) return null;

  final context = SecurityContext();
  context.setTrustedCertificatesBytes(utf8.encode(caCertificatePem));
  return context;
}
