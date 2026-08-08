import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:docflow/generated/app_localizations.dart';
import '../../domain/entities/template_sort_option.dart';
import '../providers/template_provider.dart';

class FilterPanel extends StatefulWidget {
  final FocusNode? searchFocusNode;

  const FilterPanel({super.key, this.searchFocusNode});

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  String _tagFilterText = '';

  String _sortLabel(AppLocalizations l10n, TemplateSortOption option) {
    return switch (option) {
      TemplateSortOption.recentlyUpdated => l10n.sortRecentlyUpdated,
      TemplateSortOption.recentlyCreated => l10n.sortRecentlyCreated,
      TemplateSortOption.titleAsc => l10n.sortTitleAsc,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<TemplateProvider>();

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withAlpha((255 * 0.3).round()),
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.filters, style: textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              key: const Key('mainSearchField'),
              focusNode: widget.searchFocusNode,
              decoration: InputDecoration(
                labelText: l10n.search,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                filled: true,
              ),
              onChanged: provider.search,
            ),
            const SizedBox(height: 16),
            Consumer<TemplateProvider>(
              builder: (context, provider, child) {
                return DropdownButtonFormField<TemplateSortOption>(
                  initialValue: provider.sortOption,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.sortLabel,
                    prefixIcon: const Icon(Icons.sort),
                    border: const OutlineInputBorder(),
                    filled: true,
                    isDense: true,
                  ),
                  items: TemplateSortOption.values
                      .map((option) => DropdownMenuItem(
                            value: option,
                            child: Text(
                              _sortLabel(l10n, option),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (option) {
                    if (option != null) provider.setSortOption(option);
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            Text(l10n.tags, style: textTheme.titleMedium),
            const Divider(),
            Consumer<TemplateProvider>(
              builder: (context, provider, child) {
                if (provider.allTags.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    key: const Key('tagSearchField'),
                    decoration: InputDecoration(
                      hintText: l10n.searchTagsHint,
                      prefixIcon: const Icon(Icons.filter_alt_outlined),
                      border: const OutlineInputBorder(),
                      isDense: true,
                      filled: true,
                    ),
                    onChanged: (value) => setState(() => _tagFilterText = value),
                  ),
                );
              },
            ),
            Expanded(
              child: Consumer<TemplateProvider>(
                builder: (context, provider, child) {
                  if (provider.allTags.isEmpty) {
                    return Center(
                      child: Text(l10n.noTagsFound),
                    );
                  }

                  final counts = {
                    for (final entry in provider.tagCounts)
                      entry.$1.toLowerCase(): entry.$2,
                  };

                  final query = _tagFilterText.trim().toLowerCase();
                  final visibleTags = query.isEmpty
                      ? provider.allTags
                      : provider.allTags
                          .where((tag) => tag.toLowerCase().contains(query))
                          .toList();

                  if (visibleTags.isEmpty) {
                    return Center(child: Text(l10n.noTagsFound));
                  }

                  return ListView.builder(
                    itemCount: visibleTags.length,
                    itemBuilder: (context, index) {
                      final tag = visibleTags[index];
                      final count = counts[tag.toLowerCase()];
                      return CheckboxListTile(
                        title: Text(count != null ? '$tag ($count)' : tag),
                        value: provider.selectedTags[tag] ?? false,
                        onChanged: (bool? value) {
                          provider.updateTag(tag, value ?? false);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
