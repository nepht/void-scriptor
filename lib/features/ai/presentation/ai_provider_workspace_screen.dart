import 'package:flutter/material.dart';

class AiProviderWorkspaceScreen extends StatelessWidget {
  const AiProviderWorkspaceScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AI PROVIDERS')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        _ProviderTile(
          name: 'OpenAI',
          status: 'Credential configured',
          detail: 'Cloud provider',
        ),
        _ProviderTile(
          name: 'Gemini',
          status: 'Not configured',
          detail: 'Cloud provider',
        ),
        _ProviderTile(
          name: 'Ollama',
          status: 'Local endpoint',
          detail: 'http://localhost:11434',
        ),
        _ProviderTile(
          name: 'ComfyUI',
          status: 'Local endpoint',
          detail: 'http://localhost:8188',
        ),
      ],
    ),
  );
}

class _ProviderTile extends StatelessWidget {
  const _ProviderTile({
    required this.name,
    required this.status,
    required this.detail,
  });
  final String name;
  final String status;
  final String detail;
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
        onPressed: () {},
        child: const Text('Configure'),
      ),
    ),
  );
}
