import 'package:flutter/material.dart';

class TagInputField extends StatefulWidget {
  final List<String> tags;
  final List<String> suggestions;
  final ValueChanged<List<String>> onChanged;
  final String? labelText;

  const TagInputField({
    super.key,
    required this.tags,
    required this.suggestions,
    required this.onChanged,
    this.labelText,
  });

  @override
  State<TagInputField> createState() => _TagInputFieldState();
}

class _TagInputFieldState extends State<TagInputField> {
  late List<String> _tags;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _tags = List.of(widget.tags);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _containsIgnoreCase(String tag) =>
      _tags.any((t) => t.toLowerCase() == tag.toLowerCase());

  void _addTag(String raw) {
    final trimmed = raw.trim();
    _textController.clear();
    if (trimmed.isEmpty || _containsIgnoreCase(trimmed)) return;

    setState(() => _tags.add(trimmed));
    widget.onChanged(_tags);
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
    widget.onChanged(_tags);
  }

  @override
  Widget build(BuildContext context) {
    final available =
        widget.suggestions.where((s) => !_containsIgnoreCase(s)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _tags
                  .map((tag) => Chip(
                        label: Text(tag),
                        onDeleted: () => _removeTag(tag),
                      ))
                  .toList(),
            ),
          ),
        RawAutocomplete<String>(
          textEditingController: _textController,
          focusNode: _focusNode,
          optionsBuilder: (textEditingValue) {
            final query = textEditingValue.text.trim().toLowerCase();
            if (query.isEmpty) return const Iterable<String>.empty();
            return available.where((s) => s.toLowerCase().contains(query));
          },
          onSelected: _addTag,
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: widget.labelText,
                border: const OutlineInputBorder(),
                filled: true,
              ),
              onFieldSubmitted: (value) {
                _addTag(value);
                onFieldSubmitted();
              },
              onChanged: (value) {
                if (value.endsWith(',')) {
                  _addTag(value.substring(0, value.length - 1));
                }
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200, maxWidth: 400),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        dense: true,
                        title: Text(option),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
