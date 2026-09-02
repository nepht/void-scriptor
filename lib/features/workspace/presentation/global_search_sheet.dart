// Step 145.27 Core Worldbuilding Reduction: sheet search global lintas domain.
// Hasil dari [GlobalSearchLauncher] dirender sebagai daftar; memilih hit asset
// menulis SelectionModel ter-typed ke selectionProvider (jalur produksi yang
// sama dengan Explorer), memilih hit faction memicu callback navigasi khusus.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/asset_type.dart';
import '../../../core/selection/selection_controller.dart';
import '../../../core/selection/selection_model.dart';
import '../application/global_search_launcher.dart';

/// Membuka sheet search global di atas navigator konteks saat ini.
Future<void> showGlobalSearchSheet(
  BuildContext context, {
  required GlobalSearchLauncher launcher,
  required String projectId,
  void Function(String factionId, String factionName)? onSelectFaction,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _GlobalSearchSheet(
      launcher: launcher,
      projectId: projectId,
      onSelectFaction: onSelectFaction,
    ),
  );
}

class _GlobalSearchSheet extends StatefulWidget {
  const _GlobalSearchSheet({
    required this.launcher,
    required this.projectId,
    this.onSelectFaction,
  });

  final GlobalSearchLauncher launcher;
  final String projectId;
  final void Function(String factionId, String factionName)? onSelectFaction;

  @override
  State<_GlobalSearchSheet> createState() => _GlobalSearchSheetState();
}

class _GlobalSearchSheetState extends State<_GlobalSearchSheet> {
  final _controller = TextEditingController();
  List<GlobalSearchHit> _hits = const [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final hits = await widget.launcher.search(
      _controller.text,
      projectId: widget.projectId,
    );
    if (!mounted) return;
    setState(() => _hits = hits);
  }

  void _openHit(GlobalSearchHit hit) {
    Navigator.of(context).pop();
    if (hit.assetType == null) {
      widget.onSelectFaction?.call(hit.id, hit.title);
      return;
    }
    ProviderScope.containerOf(context, listen: false)
        .read(selectionProvider.notifier)
        .select(
          SelectionModel(
            assetId: hit.id,
            assetType: hit.assetType!,
            projectId: widget.projectId,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Cari di Proyek',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Karakter, lokasi, novel, faksi...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _runSearch, child: const Text('Cari')),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _hits.length,
                itemBuilder: (context, index) {
                  final hit = _hits[index];
                  return ListTile(
                    leading: Icon(_iconFor(hit)),
                    title: Text(hit.title),
                    subtitle: Text(hit.subtitle),
                    onTap: () => _openHit(hit),
                  );
                },
              ),
            ),
            if (_hits.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Ketik untuk mencari di seluruh proyek.'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(GlobalSearchHit hit) {
    switch (hit.assetType) {
      case AssetType.character:
        return Icons.person_outline;
      case AssetType.environment:
        return Icons.public_outlined;
      case AssetType.story:
        return Icons.auto_stories_outlined;
      case null:
        return Icons.flag_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}
