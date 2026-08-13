import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/commands/command_registry.dart';
import '../domain/asset_search_query.dart';

class GlobalSearchOverlay extends StatefulWidget {
  const GlobalSearchOverlay({
    super.key,
    required this.assets,
    this.commands = const [],
  });
  final List<SearchableAsset> assets;
  final List<AppCommand> commands;

  @override
  State<GlobalSearchOverlay> createState() => _GlobalSearchOverlayState();
}

class _GlobalSearchOverlayState extends State<GlobalSearchOverlay> {
  final _controller = TextEditingController();
  int _selected = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Object> get _results {
    final query = _controller.text.trim().toLowerCase();
    final commands = widget.commands.where(
      (command) =>
          query.startsWith('>') &&
          (query.length == 1 ||
              command.label.toLowerCase().contains(query.substring(1).trim())),
    );
    final assets = widget.assets.where(
      (asset) =>
          query.isEmpty ||
          !query.startsWith('>') &&
              (asset.name.toLowerCase().contains(query) ||
                  asset.tags.any((tag) => tag.contains(query))),
    );
    return [...commands, ...assets].take(30).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return Dialog(
      child: Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.arrowDown): _MoveIntent(1),
          SingleActivator(LogicalKeyboardKey.arrowUp): _MoveIntent(-1),
          SingleActivator(LogicalKeyboardKey.enter): _SubmitIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            _MoveIntent: CallbackAction<_MoveIntent>(
              onInvoke: (intent) {
                if (results.isNotEmpty) {
                  setState(
                    () => _selected = (_selected + intent.delta).clamp(
                      0,
                      results.length - 1,
                    ),
                  );
                }
                return null;
              },
            ),
            _SubmitIntent: CallbackAction<_SubmitIntent>(
              onInvoke: (_) {
                if (results.isNotEmpty) {
                  Navigator.of(context).pop(results[_selected]);
                }
                return null;
              },
            ),
          },
          child: SizedBox(
            width: 560,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    autofocus: true,
                    controller: _controller,
                    onChanged: (_) => setState(() => _selected = 0),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search project...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (results.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No results'),
                    ),
                  if (results.isNotEmpty)
                    ...results.asMap().entries.map((entry) {
                      final item = entry.value;
                      final label = item is AppCommand
                          ? item.label
                          : (item as SearchableAsset).name;
                      final subtitle = item is AppCommand
                          ? 'Command'
                          : (item as SearchableAsset).type.name;
                      return ListTile(
                        selected: entry.key == _selected,
                        title: Text(label),
                        subtitle: Text(subtitle),
                        onTap: () => Navigator.of(context).pop(item),
                      );
                    }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoveIntent extends Intent {
  const _MoveIntent(this.delta);
  final int delta;
}

class _SubmitIntent extends Intent {
  const _SubmitIntent();
}
