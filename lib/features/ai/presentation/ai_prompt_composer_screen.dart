import 'package:flutter/material.dart';

import '../application/prompt_compiler.dart';
import '../application/prompt_composer.dart';
import '../domain/ai_context.dart';

class AiPromptComposerScreen extends StatefulWidget {
  const AiPromptComposerScreen({super.key, this.contextData});
  final AiContext? contextData;

  @override
  State<AiPromptComposerScreen> createState() => _AiPromptComposerScreenState();
}

class _AiPromptComposerScreenState extends State<AiPromptComposerScreen> {
  final _editor = TextEditingController();
  final PromptTarget _target = PromptTarget.video;
  AiContextOptions _options = const AiContextOptions();
  bool _modified = false;

  AiContext get _context =>
      widget.contextData ??
      const AiContext(
        projectId: 'current-project',
        characterContexts: [],
        environmentContext: null,
        sceneContext: null,
        timelineContext: null,
      );

  void _compose() {
    final document = PromptComposer().compose(
      context: _context,
      target: _target,
      options: _options,
    );
    final compiled = PromptCompiler().compile(document);
    setState(() {
      _editor.text = compiled.text.isEmpty
          ? 'No scene context selected. Resolve a Scene to generate a contextual prompt.'
          : compiled.text;
      _editor.selection = TextSelection.collapsed(offset: _editor.text.length);
      _modified = false;
    });
  }

  void _setOption(AiContextOptions Function(AiContextOptions) update) {
    setState(() {
      _options = update(_options);
    });
  }

  @override
  void dispose() {
    _editor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Prompt Composer'),
        actions: [
          IconButton(
            tooltip: 'Generate Prompt',
            onPressed: _compose,
            icon: const Icon(Icons.auto_awesome),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 760;
          final panel = _ContextPanel(
            options: _options,
            onChanged: _setOption,
            target: _target,
          );
          final editor = _PromptEditor(
            controller: _editor,
            modified: _modified,
            onChanged: (_) => setState(() {
              _modified = true;
            }),
          );
          if (narrow) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                panel,
                const SizedBox(height: 16),
                SizedBox(height: 520, child: editor),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 280, child: panel),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: editor,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ContextPanel extends StatelessWidget {
  const _ContextPanel({
    required this.options,
    required this.onChanged,
    required this.target,
  });
  final AiContextOptions options;
  final void Function(AiContextOptions Function(AiContextOptions)) onChanged;
  final PromptTarget target;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CONTEXT', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Text(
              'Target: ${target.name}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          _toggle(
            'Character',
            options.includeCharacter,
            (value) => onChanged(
              (old) => AiContextOptions(
                includeCharacter: value,
                includeMode: old.includeMode,
                includeIdentity: old.includeIdentity,
                includeWardrobe: old.includeWardrobe,
                includeWeapons: old.includeWeapons,
                includeEnvironment: old.includeEnvironment,
                includeTimeline: old.includeTimeline,
                includeContinuity: old.includeContinuity,
              ),
            ),
          ),
          _toggle(
            'Identity Locks',
            options.includeIdentity,
            (value) => onChanged(
              (old) => AiContextOptions(
                includeCharacter: old.includeCharacter,
                includeMode: old.includeMode,
                includeIdentity: value,
                includeWardrobe: old.includeWardrobe,
                includeWeapons: old.includeWeapons,
                includeEnvironment: old.includeEnvironment,
                includeTimeline: old.includeTimeline,
                includeContinuity: old.includeContinuity,
              ),
            ),
          ),
          _toggle(
            'Wardrobe',
            options.includeWardrobe,
            (value) => onChanged(
              (old) => AiContextOptions(
                includeCharacter: old.includeCharacter,
                includeMode: old.includeMode,
                includeIdentity: old.includeIdentity,
                includeWardrobe: value,
                includeWeapons: old.includeWeapons,
                includeEnvironment: old.includeEnvironment,
                includeTimeline: old.includeTimeline,
                includeContinuity: old.includeContinuity,
              ),
            ),
          ),
          _toggle(
            'Weapon',
            options.includeWeapons,
            (value) => onChanged(
              (old) => AiContextOptions(
                includeCharacter: old.includeCharacter,
                includeMode: old.includeMode,
                includeIdentity: old.includeIdentity,
                includeWardrobe: old.includeWardrobe,
                includeWeapons: value,
                includeEnvironment: old.includeEnvironment,
                includeTimeline: old.includeTimeline,
                includeContinuity: old.includeContinuity,
              ),
            ),
          ),
          _toggle(
            'Environment',
            options.includeEnvironment,
            (value) => onChanged(
              (old) => AiContextOptions(
                includeCharacter: old.includeCharacter,
                includeMode: old.includeMode,
                includeIdentity: old.includeIdentity,
                includeWardrobe: old.includeWardrobe,
                includeWeapons: old.includeWeapons,
                includeEnvironment: value,
                includeTimeline: old.includeTimeline,
                includeContinuity: old.includeContinuity,
              ),
            ),
          ),
          _toggle(
            'Timeline',
            options.includeTimeline,
            (value) => onChanged(
              (old) => AiContextOptions(
                includeCharacter: old.includeCharacter,
                includeMode: old.includeMode,
                includeIdentity: old.includeIdentity,
                includeWardrobe: old.includeWardrobe,
                includeWeapons: old.includeWeapons,
                includeEnvironment: old.includeEnvironment,
                includeTimeline: value,
                includeContinuity: old.includeContinuity,
              ),
            ),
          ),
        ],
      ),
    ),
  );
  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) =>
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: Text(label),
        value: value,
        onChanged: (next) => onChanged(next ?? false),
      );
}

class _PromptEditor extends StatelessWidget {
  const _PromptEditor({
    required this.controller,
    required this.modified,
    required this.onChanged,
  });
  final TextEditingController controller;
  final bool modified;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'MASTER PROMPT',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (modified)
                const Flexible(
                  child: Text(
                    '• Modified',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              expands: true,
              maxLines: null,
              minLines: null,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                hintText: 'Generate a prompt or write your own...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
