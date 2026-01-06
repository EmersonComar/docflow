import 'package:flutter/material.dart';
import 'package:docflow/generated/app_localizations.dart';

class VariableInputDialog extends StatefulWidget {
  final Set<String> variables;

  const VariableInputDialog({super.key, required this.variables});

  @override
  State<VariableInputDialog> createState() => _VariableInputDialogState();
}

class _VariableInputDialogState extends State<VariableInputDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (var variable in widget.variables) {
      _controllers[variable] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onConfirm() {
    if (_formKey.currentState!.validate()) {
      final values = _controllers.map((key, value) => MapEntry(key, value.text));
      Navigator.of(context).pop(values);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.fillVariablesTitle),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.variables.map((variable) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: TextFormField(
                  controller: _controllers[variable],
                  decoration: InputDecoration(
                    labelText: variable,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.pleaseInsertContent; 
                    }
                    return null;
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          onPressed: _onConfirm,
          child: Text(AppLocalizations.of(context)!.confirmCopy),
        ),
      ],
    );
  }
}
