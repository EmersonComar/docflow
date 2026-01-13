import 'package:file_picker/file_picker.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:provider/provider.dart';
import 'package:docflow/generated/app_localizations.dart';
import '../../domain/entities/template.dart';
import '../providers/template_provider.dart';


class AddTemplateDialog extends StatefulWidget {
  final Template? template;

  const AddTemplateDialog({super.key, this.template});

  @override
  State<AddTemplateDialog> createState() => _AddTemplateDialogState();
}

class _AddTemplateDialogState extends State<AddTemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tituloController;
  late final TextEditingController _conteudoController;
  late final TextEditingController _tagsController;
  
  String _markdownPreview = '';
  String? _errorMessage;
  late bool _markdownEnabled;
  late bool _snippetsEnabled;

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(text: widget.template?.titulo ?? '');
    _conteudoController = TextEditingController(text: widget.template?.conteudo ?? '');
    _tagsController = TextEditingController(text: widget.template?.tags.join(', ') ?? '');
    _markdownPreview = _conteudoController.text;
    _markdownEnabled = widget.template?.markdownEnabled ?? true;
    _snippetsEnabled = widget.template?.snippetsEnabled ?? true;
    
    _conteudoController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _conteudoController.removeListener(_onContentChanged);
    _tituloController.dispose();
    _conteudoController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    _updateMarkdownPreview();
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  void _updateMarkdownPreview() {
    setState(() {
      _markdownPreview = _conteudoController.text;
    });
  }

  Future<void> _importMarkdown() async {
    setState(() {
      _errorMessage = null;
    });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['md', 'markdown'],
    );

    if (result != null) {
      final file = File(result.files.single.path!);
      try {
        final content = await file.readAsString();
        _conteudoController.text = content;
      } on FileSystemException {
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.importMarkdownError;
        });
      }
    }
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<TemplateProvider>();
    final isEditing = widget.template != null;

    final templateData = Template(
      id: widget.template?.id,
      titulo: _tituloController.text.trim(),
      conteudo: _conteudoController.text,
      tags: _tagsController.text
          .split(',')
          .map((e) => e.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      markdownEnabled: _markdownEnabled,
      snippetsEnabled: _snippetsEnabled,
    );

    if (isEditing) {
      await provider.updateTemplate(templateData);
    } else {
      await provider.addTemplate(templateData);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.template != null;
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(isEditing ? AppLocalizations.of(context)!.editTemplate : AppLocalizations.of(context)!.newTemplate),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _tituloController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.titleLabel,
                  border: const OutlineInputBorder(),
                  filled: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(context)!.pleaseInsertTitle;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _conteudoController,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)!.contentLabel,
                                border: const OutlineInputBorder(),
                                filled: true,
                                alignLabelWithHint: true,
                              ),
                              maxLines: null,
                              expands: true,
                              textAlignVertical: TextAlignVertical.top,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return AppLocalizations.of(context)!.pleaseInsertContent;
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: colorScheme.outline.withAlpha((255 * 0.2).round()),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      _markdownEnabled 
                                          ? AppLocalizations.of(context)!.markdownPreview
                                          : AppLocalizations.of(context)!.plainTextPreview,
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: colorScheme.outline,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: _markdownEnabled
                                            ? GptMarkdown(
                                                _markdownPreview,
                                                style: Theme.of(context).textTheme.bodyMedium,
                                              )
                                            : SelectableText(
                                                _markdownPreview,
                                                style: Theme.of(context).textTheme.bodyMedium,
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tagsController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.tagsLabel,
                  border: const OutlineInputBorder(),
                  filled: true,
                ),
              ),
              const SizedBox(height: 8),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  AppLocalizations.of(context)!.templateSettings,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                leading: const Icon(Icons.settings, size: 20),
                dense: true,
                visualDensity: VisualDensity.compact,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          title: Text(
                            AppLocalizations.of(context)!.enableMarkdown,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          value: _markdownEnabled,
                          onChanged: (value) {
                            setState(() {
                              _markdownEnabled = value ?? true;
                            });
                          },
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ),
                      Expanded(
                        child: CheckboxListTile(
                          title: Text(
                            AppLocalizations.of(context)!.enableSnippets,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          value: _snippetsEnabled,
                          onChanged: (value) {
                            setState(() {
                              _snippetsEnabled = value ?? true;
                            });
                          },
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.cancel),
          label: Text(AppLocalizations.of(context)!.cancel),
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.onSurface,
          ),
        ),
        TextButton.icon(
          onPressed: _importMarkdown,
          icon: const Icon(Icons.upload_file),
          label: Text(AppLocalizations.of(context)!.importMarkdown),
        ),
        ElevatedButton.icon(
          onPressed: _saveTemplate,
          icon: const Icon(Icons.save),
          label: Text(AppLocalizations.of(context)!.save),
        ),
      ],
    );
  }
}
