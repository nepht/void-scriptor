import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/security/credential_store.dart';
import '../domain/ai_provider_settings.dart';
import '../infrastructure/providers/gemini/gemini_provider.dart';
import '../infrastructure/providers/openai/openai_provider.dart';

class AiProviderWorkspaceScreen extends StatefulWidget {
  const AiProviderWorkspaceScreen({super.key, this.credentialStore});

  final CredentialStore? credentialStore;

  @override
  State<AiProviderWorkspaceScreen> createState() =>
      _AiProviderWorkspaceScreenState();
}

class _AiProviderWorkspaceScreenState extends State<AiProviderWorkspaceScreen> {
  static const _providers = [
    _ProviderDefinition.cloud(
      name: 'OpenAI',
      credentialKey: OpenAiProvider.credentialKey,
    ),
    _ProviderDefinition.cloud(
      name: 'Gemini',
      credentialKey: GeminiProvider.credentialKey,
    ),
    _ProviderDefinition.local(
      name: 'Ollama',
      endpointKey: AiProviderSettingKeys.ollamaEndpoint,
      defaultEndpoint: AiProviderSettingKeys.defaultOllamaEndpoint,
    ),
    _ProviderDefinition.local(
      name: 'ComfyUI',
      endpointKey: AiProviderSettingKeys.comfyUiEndpoint,
      defaultEndpoint: AiProviderSettingKeys.defaultComfyUiEndpoint,
    ),
  ];

  late final CredentialStore _store =
      widget.credentialStore ??
      const SecureCredentialStore(FlutterSecureStorage());
  final Map<String, String?> _values = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    for (final provider in _providers) {
      _values[provider.storageKey] = await _store.read(provider.storageKey);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _configure(_ProviderDefinition provider) async {
    final result = await showDialog<_ConfigurationResult>(
      context: context,
      builder: (context) => _ProviderConfigurationDialog(
        provider: provider,
        configured: _isConfigured(provider),
        currentEndpoint:
            _values[provider.storageKey] ?? provider.defaultEndpoint,
      ),
    );
    if (result == null) return;
    if (result.remove) {
      await _store.delete(provider.storageKey);
      _values[provider.storageKey] = null;
    } else {
      await _store.write(key: provider.storageKey, value: result.value!);
      _values[provider.storageKey] = result.value;
    }
    if (mounted) setState(() {});
  }

  bool _isConfigured(_ProviderDefinition provider) =>
      (_values[provider.storageKey]?.trim().isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AI PROVIDERS')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              for (final provider in _providers)
                _ProviderTile(
                  name: provider.name,
                  status: provider.isCloud
                      ? (_isConfigured(provider)
                            ? 'Credential configured'
                            : 'Not configured')
                      : 'Local endpoint',
                  detail: provider.isCloud
                      ? 'Cloud provider'
                      : (_values[provider.storageKey] ??
                            provider.defaultEndpoint!),
                  onConfigure: () => _configure(provider),
                ),
            ],
          ),
  );
}

class _ProviderDefinition {
  const _ProviderDefinition.cloud({
    required this.name,
    required String credentialKey,
  }) : storageKey = credentialKey,
       defaultEndpoint = null,
       isCloud = true;

  const _ProviderDefinition.local({
    required this.name,
    required String endpointKey,
    required this.defaultEndpoint,
  }) : storageKey = endpointKey,
       isCloud = false;

  final String name;
  final String storageKey;
  final String? defaultEndpoint;
  final bool isCloud;
}

class _ConfigurationResult {
  const _ConfigurationResult.save(this.value) : remove = false;
  const _ConfigurationResult.remove() : value = null, remove = true;

  final String? value;
  final bool remove;
}

class _ProviderConfigurationDialog extends StatefulWidget {
  const _ProviderConfigurationDialog({
    required this.provider,
    required this.configured,
    required this.currentEndpoint,
  });

  final _ProviderDefinition provider;
  final bool configured;
  final String? currentEndpoint;

  @override
  State<_ProviderConfigurationDialog> createState() =>
      _ProviderConfigurationDialogState();
}

class _ProviderConfigurationDialogState
    extends State<_ProviderConfigurationDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.provider.isCloud ? '' : widget.currentEndpoint,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Configure ${widget.provider.name}'),
    content: TextField(
      controller: _controller,
      obscureText: widget.provider.isCloud,
      enableSuggestions: !widget.provider.isCloud,
      autocorrect: !widget.provider.isCloud,
      decoration: InputDecoration(
        labelText: widget.provider.isCloud ? 'API credential' : 'Endpoint URL',
        helperText: widget.provider.isCloud
            ? 'Stored in the operating system credential vault.'
            : 'Use an http:// or https:// endpoint.',
      ),
    ),
    actions: [
      if (widget.provider.isCloud && widget.configured)
        TextButton(
          onPressed: () =>
              Navigator.pop(context, const _ConfigurationResult.remove()),
          child: const Text('Remove'),
        ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          final value = _controller.text.trim();
          if (value.isNotEmpty) {
            Navigator.pop(context, _ConfigurationResult.save(value));
          }
        },
        child: const Text('Save'),
      ),
    ],
  );
}

class _ProviderTile extends StatelessWidget {
  const _ProviderTile({
    required this.name,
    required this.status,
    required this.detail,
    required this.onConfigure,
  });

  final String name;
  final String status;
  final String detail;
  final VoidCallback onConfigure;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: Text(name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(status), Text(detail)],
      ),
      isThreeLine: true,
      trailing: OutlinedButton(
        onPressed: onConfigure,
        child: const Text('Configure'),
      ),
    ),
  );
}
