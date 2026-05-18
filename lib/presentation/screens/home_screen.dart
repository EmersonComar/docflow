import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/database_provider.dart';
import '../providers/locale_provider.dart';
import 'package:docflow/generated/app_localizations.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import '../../domain/entities/template.dart';
import '../providers/template_provider.dart';
import '../providers/theme_notifier.dart';
import '../widgets/add_template_dialog.dart';

import '../widgets/filter_panel.dart';
import '../../core/utils/string_utils.dart';
import '../widgets/variable_input_dialog.dart';
import 'changelog_screen.dart';
import '../providers/changelog_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final FocusNode _searchFocusNode;
  late final FocusNode _rootFocusNode;

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();
    _rootFocusNode = FocusNode();
    _rootFocusNode.addListener(_onRootFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TemplateProvider>().initialize();
      _rootFocusNode.requestFocus();
    });
  }

  void _onRootFocusChange() {
    if (!_rootFocusNode.hasFocus) {
      final primary = FocusManager.instance.primaryFocus;
      final isDescendant = primary != null &&
          primary.ancestors.contains(_rootFocusNode);
      final isDialog = primary != null &&
          primary.context != null &&
          ModalRoute.of(primary.context!) != ModalRoute.of(context);
      if (!isDescendant && !isDialog) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_rootFocusNode.hasFocus) {
            _rootFocusNode.requestFocus();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _rootFocusNode.removeListener(_onRootFocusChange);
    _rootFocusNode.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _showChangelog() {
    context.read<ChangelogProvider>().markAsViewed();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ChangelogScreen(),
      ),
    );
  }

  void _cycleLanguage() {
    final provider = context.read<LocaleProvider>();
    final currentCode = provider.locale?.languageCode ?? 'pt';
    Locale nextLocale;
    if (currentCode == 'pt') {
      nextLocale = const Locale('en');
    } else if (currentCode == 'en') {
      nextLocale = const Locale('es');
    } else {
      nextLocale = const Locale('pt');
    }
    provider.setLocale(nextLocale);
  }

  Future<void> _openAnotherFile(BuildContext context) async {
    await context.read<DatabaseProvider>().disconnect();
  }

  void _showAddTemplateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddTemplateDialog(),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showAboutDialog(
      context: context,
      applicationName: 'DocFlow',
      applicationVersion: '2.2.0',
      applicationIcon: const Icon(Icons.folder_special_rounded, size: 48),
      children: [
        const SizedBox(height: 16),
        Text(l10n.aboutTitle),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final url = Uri.parse('https://github.com/EmersonComar/docflow/issues');
            if (await canLaunchUrl(url)) {
              await launchUrl(url);
            }
          },
          child: Text(
            l10n.supportLabel,
            style: const TextStyle(
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();
    final localeProvider = context.watch<LocaleProvider>();
    final dbProvider = context.watch<DatabaseProvider>();
    final dbName = dbProvider.currentDbName;

    return Focus(
      focusNode: _rootFocusNode,
      autofocus: true,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent) {
          final isModifierPressed = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;
          if (isModifierPressed) {
            if (event.logicalKey == LogicalKeyboardKey.keyN) {
              _showAddTemplateDialog(context);
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.keyF) {
              _searchFocusNode.requestFocus();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.keyT) {
              themeNotifier.toggleTheme();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.keyH) {
              _showChangelog();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.keyL) {
              _cycleLanguage();
              return KeyEventResult.handled;
            }
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context)!.appTitle),
            if (dbName != null)
              Text(
                dbName,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings_outlined),
            tooltip: AppLocalizations.of(context)!.settingsMenu,
            onSelected: (value) async {
              switch (value) {
                case 'news':
                  _showChangelog();
                  break;
                case 'open':
                  await _openAnotherFile(context);
                  break;
                case 'theme':
                  themeNotifier.toggleTheme();
                  break;
                case 'lang':
                  _cycleLanguage();
                  break;
                case 'about':
                  _showAboutDialog(context);
                  break;
              }
            },
            itemBuilder: (context) {
              final l10n = AppLocalizations.of(context)!;
              final hasNews = context.read<ChangelogProvider>().hasNewVersion;

              return [
                PopupMenuItem(
                  value: 'news',
                  child: ListTile(
                    leading: Badge(
                      isLabelVisible: hasNews,
                      smallSize: 10,
                      child: const Icon(Icons.new_releases_outlined),
                    ),
                    title: Text(l10n.newsTitle),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'open',
                  child: ListTile(
                    leading: const Icon(Icons.folder_open_rounded),
                    title: Text(l10n.openAnotherFile),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'theme',
                  child: ListTile(
                    leading: Icon(_getThemeIcon(themeNotifier.themeMode)),
                    title: Text(l10n.changeTheme),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'lang',
                  child: ListTile(
                    leading: const Icon(Icons.translate),
                    title: Text(l10n.changeLanguage),
                    trailing: Text(
                      localeProvider.locale?.languageCode.toUpperCase() ?? 'PT',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'about',
                  child: ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(l10n.aboutTitle),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Row(
        children: [
          SizedBox(width: 250, child: FilterPanel(searchFocusNode: _searchFocusNode)),
          const Expanded(child: _TemplateList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTemplateDialog(context),
        tooltip: AppLocalizations.of(context)!.newTemplateFab,
        child: const Icon(Icons.add),
      ),
    ));
  }

  IconData _getThemeIcon(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => Icons.dark_mode,
      ThemeMode.dark => Icons.light_mode,
      ThemeMode.system => Icons.brightness_auto,
    };
  }
}


class _TemplateList extends StatefulWidget {
  const _TemplateList();

  @override
  State<_TemplateList> createState() => _TemplateListState();
}

class _TemplateListState extends State<_TemplateList> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.9) {
      context.read<TemplateProvider>().loadMore();
    }
  }

  String _getTranslatedErrorMessage(BuildContext context, (String, List<Object>) error) {
    final l10n = AppLocalizations.of(context)!;
    final key = error.$1;
    final args = error.$2;

    switch (key) {
      case 'unexpectedError':
        return l10n.unexpectedError(args.isNotEmpty ? args[0] as String : '');
      case 'loadMoreFailed':
        return l10n.loadMoreFailed(args.isNotEmpty ? args[0] as String : '');
      case 'databaseInitializationFailed':
        return l10n.databaseInitializationFailed(args.isNotEmpty ? args[0] as String : '');
      case 'createTemplateFailed':
        return l10n.createTemplateFailed(args.isNotEmpty ? args[0] as String : '');
      case 'templateIdCannotBeNull':
        return l10n.templateIdCannotBeNull;
      case 'updateTemplateFailed':
        return l10n.updateTemplateFailed(args.isNotEmpty ? args[0] as String : '');
      case 'deleteTemplateFailed':
        return l10n.deleteTemplateFailed(args.isNotEmpty ? args[0] as String : '');
      case 'loadTemplatesFailed':
        return l10n.loadTemplatesFailed(args.isNotEmpty ? args[0] as String : '');
      case 'loadTagsFailed':
        return l10n.loadTagsFailed(args.isNotEmpty ? args[0] as String : '');
      default:
        return l10n.unknownError;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TemplateProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.templates.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getTranslatedErrorMessage(context, provider.error!),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => provider.initialize(),
                    icon: const Icon(Icons.refresh),
                    label: Text(AppLocalizations.of(context)!.tryAgain),
                  ),
                ],
              ),
            ),
          );
        }

        if (provider.templates.isEmpty) {
          return Center(
            child: Text(AppLocalizations.of(context)!.noTemplatesFound),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
          itemCount: provider.templates.length + (provider.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == provider.templates.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return _TemplateCard(template: provider.templates[index]);
          },
        );
      },
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final Template template;

  const _TemplateCard({required this.template});

  void _showEditTemplateDialog(BuildContext context, Template template) {
    showDialog(
      context: context,
      builder: (context) => AddTemplateDialog(template: template),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, Template template) {
    showDialog(
      context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.confirmDeleteTitle),
            content: Text(
              AppLocalizations.of(context)!.confirmDeleteContent(template.titulo),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(AppLocalizations.of(context)!.cancelButton),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              TextButton.icon(
                icon: const Icon(Icons.delete),
                label: Text(
                  AppLocalizations.of(context)!.delete,
                  style: TextStyle(
                    color: Theme.of(dialogContext).colorScheme.error,
                  ),
                ),
                onPressed: () {
                  context.read<TemplateProvider>().deleteTemplate(template.id!);
                  Navigator.of(dialogContext).pop();
                },
              ),
            ],
          );
        },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final provider = context.watch<TemplateProvider>();
    final isExpanded = provider.isTemplateExpanded(template.id);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outline.withAlpha((255 * 0.2).round()),
        ),
      ),
      child: InkWell(
        splashColor: Colors.transparent,
        highlightColor: colorScheme.onSurface.withAlpha((255 * 0.1).round()),
        onTap: () => provider.toggleTemplateExpansion(template.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      template.titulo,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                  _TemplateMenuButton(
                    template: template,
                    onEdit: () => _showEditTemplateDialog(context, template),
                    onDelete: () => _showDeleteConfirmationDialog(context, template),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              isExpanded
                  ? (template.markdownEnabled
                      ? GptMarkdown(
                          template.conteudo,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        )
                      : SelectableText(
                          template.conteudo,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ))
                  : Text(
                      template.conteudo,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
              const SizedBox(height: 16),
              if (template.tags.isNotEmpty && template.tags.first.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: template.tags
                      .map((tag) => Chip(label: Text(tag)))
                      .toList(),
                ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    String contentToCopy = template.conteudo;
                    
                    if (template.snippetsEnabled) {
                      final variables = StringUtils.extractVariables(contentToCopy);

                      if (variables.isNotEmpty) {
                        final values = await showDialog<Map<String, String>>(
                          context: context,
                          builder: (context) => VariableInputDialog(variables: variables),
                        );

                        if (values != null) {
                          contentToCopy = StringUtils.interpolate(contentToCopy, values);
                        } else {
                          return;
                        }
                      }
                    }

                    Clipboard.setData(ClipboardData(text: contentToCopy));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.contentCopied)),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy),
                  label: Text(AppLocalizations.of(context)!.copy),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplateMenuButton extends StatelessWidget {
  const _TemplateMenuButton({
    required this.template,
    required this.onEdit,
    required this.onDelete,
  });

  final Template template;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit') {
          onEdit();
        } else if (value == 'delete') {
          onDelete();
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'edit',
          child: ListTile(
            leading: const Icon(Icons.edit),
            title: Text(AppLocalizations.of(context)!.editTemplate),
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: ListTile(
            leading: const Icon(Icons.delete),
            title: Text(AppLocalizations.of(context)!.delete),
          ),
        ),
      ],
    );
  }}