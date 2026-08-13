import 'package:flutter/material.dart';
import '../../../design_system/colors/void_colors.dart';

class SceneWorkspaceScreen extends StatelessWidget {
  const SceneWorkspaceScreen({
    super.key,
    required this.sceneId,
    this.title = 'Scene',
  });
  final String sceneId;
  final String title;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: VoidColors.background,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scene — $title',
            style: const TextStyle(
              color: VoidColors.textPrimary,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Text(
            'Duration not set',
            style: TextStyle(color: VoidColors.textMuted),
          ),
          const SizedBox(height: 18),
          const _Section(
            title: 'ENVIRONMENT',
            children: [
              Text('Environment not linked'),
              Text('Zone not linked'),
              Text('Weather not linked'),
              Text('Lighting not linked'),
            ],
          ),
          const SizedBox(height: 12),
          const _Section(
            title: 'CHARACTERS',
            children: [Text('No scene characters yet')],
          ),
          const SizedBox(height: 12),
          const _Section(
            title: 'ACTION BEATS',
            children: [
              Text('No beats yet'),
              SizedBox(height: 12),
              OutlinedButton(onPressed: null, child: Text('Add Beat')),
            ],
          ),
          const SizedBox(height: 12),
          const _Section(
            title: 'CONTINUITY',
            children: [Text('No continuity changes yet')],
          ),
        ],
      ),
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card(
    color: VoidColors.panel,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: VoidColors.primaryBright,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          DefaultTextStyle(
            style: const TextStyle(
              color: VoidColors.textSecondary,
              height: 1.6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    ),
  );
}
