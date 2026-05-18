import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:docflow/generated/app_localizations.dart';
import 'package:docflow/data/models/postgres_credentials.dart';
import 'package:docflow/core/services/app_config_service.dart';
import '../providers/database_provider.dart';
import '../widgets/external_connection_form.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isWorking = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _createNew() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await FilePicker.saveFile(
      dialogTitle: l10n.selectSaveLocation,
      fileName: 'templates.db',
    );

    if (result == null || !mounted) return;

    final path = result.endsWith('.db') ? result : '$result.db';
    setState(() => _isWorking = true);

    await context.read<DatabaseProvider>().createDatabase(path);

    if (mounted) setState(() => _isWorking = false);
  }

  Future<void> _openExisting() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await FilePicker.pickFiles(
      dialogTitle: l10n.selectDatabaseFile,
      type: FileType.any,
      allowMultiple: false,
    );

    if (result == null || !mounted) return;

    final path = result.files.single.path!;
    setState(() => _isWorking = true);

    await context.read<DatabaseProvider>().openDatabase(path);

    if (mounted) setState(() => _isWorking = false);
  }

  Future<void> _connectPostgres(PostgresCredentials credentials) async {
    setState(() => _isWorking = true);

    try {
      final configService = AppConfigService();
      await configService.savePostgresCredentials(credentials);

      if (mounted) {
        await context
            .read<DatabaseProvider>()
            .openPostgresDatabase(credentials);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao conectar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isWorking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dbProvider = context.watch<DatabaseProvider>();
    final hasError = dbProvider.status == DatabaseStatus.error;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo / icon
                Icon(
                  Icons.folder_special_rounded,
                  size: 80,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  l10n.welcomeTitle,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Subtitle
                Text(
                  l10n.welcomeSubtitle,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Tab selector: Local or External
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(
                        icon: const Icon(Icons.folder_open),
                        text: 'Local',
                      ),
                      Tab(
                        icon: const Icon(Icons.cloud),
                        text: 'PostgreSQL',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Error banner
                if (hasError) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: colorScheme.onErrorContainer),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dbProvider.error == 'invalid_database_file'
                                ? l10n.invalidDatabaseFile
                                : (dbProvider.error ?? l10n.databaseNotFound),
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Loading indicator or buttons
                if (_isWorking || dbProvider.status == DatabaseStatus.loading)
                  const Center(child: CircularProgressIndicator())
                else
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Local tab
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: _createNew,
                              icon: const Icon(Icons.create_new_folder_rounded),
                              label: Text(l10n.createNewDatabase),
                              style: FilledButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: _openExisting,
                              icon: const Icon(Icons.folder_open_rounded),
                              label: Text(l10n.openExistingDatabase),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ],
                        ),
                        // PostgreSQL tab
                        SingleChildScrollView(
                          child: ExternalConnectionForm(
                            onConnect: _connectPostgres,
                          ),
                        ),
                      ],
                    ),
                  ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
