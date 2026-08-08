import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:docflow/generated/app_localizations.dart';
import 'package:docflow/data/models/postgres_credentials.dart';

class ExternalConnectionForm extends StatefulWidget {
  final PostgresCredentials? initialCredentials;
  final Function(PostgresCredentials) onConnect;
  final VoidCallback? onCancel;

  const ExternalConnectionForm({
    super.key,
    this.initialCredentials,
    required this.onConnect,
    this.onCancel,
  });

  @override
  State<ExternalConnectionForm> createState() => _ExternalConnectionFormState();
}

class _ExternalConnectionFormState extends State<ExternalConnectionForm> {
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _databaseController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  bool _isConnecting = false;
  bool _showPassword = false;
  bool _sslEnabled = false;
  bool _useSelfSignedCert = false;
  String? _caCertificatePem;
  String? _caCertificateFileName;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCredentials;
    _hostController = TextEditingController(text: initial?.host ?? '');
    _portController =
        TextEditingController(text: initial?.port.toString() ?? '5432');
    _databaseController = TextEditingController(text: initial?.database ?? '');
    _usernameController = TextEditingController(text: initial?.username ?? '');
    _passwordController = TextEditingController(text: initial?.password ?? '');
    _sslEnabled = initial?.sslEnabled ?? false;
    _caCertificatePem = initial?.caCertificatePem;
    _useSelfSignedCert = _caCertificatePem != null;
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _databaseController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickCertificateFile() async {
    setState(() {
      _error = null;
    });

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pem', 'crt', 'cer'],
    );
    if (result == null || !mounted) return;

    final path = result.files.single.path;
    if (path == null) return;

    try {
      final content = await File(path).readAsString();
      if (!content.contains('-----BEGIN CERTIFICATE-----')) {
        setState(() {
          _error = AppLocalizations.of(context)!.certificateInvalidFormat;
        });
        return;
      }

      setState(() {
        _caCertificatePem = content;
        _caCertificateFileName = result.files.single.name;
      });
    } catch (_) {
      setState(() {
        _error = AppLocalizations.of(context)!.certificateReadError;
      });
    }
  }

  void _removeCertificate() {
    setState(() {
      _caCertificatePem = null;
      _caCertificateFileName = null;
    });
  }

  Future<void> _handleConnect() async {
    setState(() {
      _error = null;
    });

    final host = _hostController.text.trim();
    final portStr = _portController.text.trim();
    final database = _databaseController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (host.isEmpty ||
        portStr.isEmpty ||
        database.isEmpty ||
        username.isEmpty ||
        password.isEmpty) {
      setState(() {
        _error = AppLocalizations.of(context)!.allFieldsRequired;
      });
      return;
    }

    final port = int.tryParse(portStr);
    if (port == null || port <= 0 || port > 65535) {
      setState(() {
        _error = AppLocalizations.of(context)!.invalidPort;
      });
      return;
    }

    if (_sslEnabled && _useSelfSignedCert && _caCertificatePem == null) {
      setState(() {
        _error = AppLocalizations.of(context)!.certificateRequiredError;
      });
      return;
    }

    setState(() => _isConnecting = true);

    try {
      final credentials = PostgresCredentials(
        host: host,
        port: port,
        database: database,
        username: username,
        password: password,
        sslEnabled: _sslEnabled,
        caCertificatePem:
            _sslEnabled && _useSelfSignedCert ? _caCertificatePem : null,
      );

      widget.onConnect(credentials);
    } catch (e) {
      setState(() {
        _error = AppLocalizations.of(context)!.connectionError(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.postgresConnectionTitle,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.postgresConnectionSubtitle,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _hostController,
              enabled: !_isConnecting,
              decoration: InputDecoration(
                labelText: l10n.serverIpLabel,
                hintText: 'localhost',
                prefixIcon: const Icon(Icons.dns),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _portController,
              enabled: !_isConnecting,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.portLabel,
                hintText: '5432',
                prefixIcon: const Icon(Icons.settings_ethernet),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _databaseController,
              enabled: !_isConnecting,
              decoration: InputDecoration(
                labelText: l10n.databaseLabel,
                hintText: 'docflow',
                prefixIcon: const Icon(Icons.storage),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              enabled: !_isConnecting,
              decoration: InputDecoration(
                labelText: l10n.usernameLabel,
                prefixIcon: const Icon(Icons.person),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              enabled: !_isConnecting,
              obscureText: !_showPassword,
              decoration: InputDecoration(
                labelText: l10n.passwordLabel,
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _showPassword = !_showPassword);
                  },
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _sslEnabled,
              onChanged: _isConnecting
                  ? null
                  : (value) => setState(() => _sslEnabled = value),
              title: Text(l10n.sslEnabled),
              secondary: Icon(
                _sslEnabled ? Icons.lock : Icons.lock_open,
                color: _sslEnabled
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              contentPadding: EdgeInsets.zero,
            ),
            if (_sslEnabled) ...[
              SwitchListTile(
                value: _useSelfSignedCert,
                onChanged: _isConnecting
                    ? null
                    : (value) => setState(() => _useSelfSignedCert = value),
                title: Text(l10n.selfSignedCertToggle),
                subtitle: Text(
                  l10n.selfSignedCertHint,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                secondary: const Icon(Icons.verified_outlined),
                contentPadding: EdgeInsets.zero,
                isThreeLine: true,
              ),
              if (_useSelfSignedCert) ...[
                const SizedBox(height: 4),
                if (_caCertificateFileName != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.description_outlined),
                    title: Text(
                      l10n.certificateSelectedLabel(_caCertificateFileName!),
                      style: textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: l10n.removeCertificateTooltip,
                      onPressed: _isConnecting ? null : _removeCertificate,
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: _isConnecting ? null : _pickCertificateFile,
                    icon: const Icon(Icons.upload_file),
                    label: Text(l10n.selectCertificateButton),
                  ),
              ],
            ],
            const SizedBox(height: 8),
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (widget.onCancel != null)
                  OutlinedButton(
                    onPressed: _isConnecting ? null : widget.onCancel,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 12.0,
                      ),
                      child: Text(l10n.cancel),
                    ),
                  ),
                FilledButton.icon(
                  onPressed: _isConnecting ? null : _handleConnect,
                  icon: _isConnecting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : const Icon(Icons.cloud_done),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 12.0,
                    ),
                    child: Text(_isConnecting ? l10n.connecting : l10n.connectButton),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
