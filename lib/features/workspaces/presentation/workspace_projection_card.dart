import 'package:flutter/material.dart';

import '../application/workspace_projection_cache.dart';

class WorkspaceProjectionCard extends StatelessWidget {
  const WorkspaceProjectionCard({
    super.key,
    required this.projectionFuture,
    this.onTapAddCharacter,
  });

  final Future<WorkspaceProjection> projectionFuture;

  /// Optional link-creation binding (145.43 friksi #1). Dipanggil dengan
  /// novel workspace id; mengembalikan projection terbaru saat sukses dan
  /// null saat dibatalkan. Null menjaga aksi absen — kartu menampilkan hint
  /// jujur, bukan tombol mati.
  final Future<WorkspaceProjection?> Function(String novelWorkspaceId)?
  onTapAddCharacter;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: _CardBody(
        initial: projectionFuture,
        onTapAddCharacter: onTapAddCharacter,
      ),
    ),
  );
}

class _CardBody extends StatefulWidget {
  const _CardBody({required this.initial, this.onTapAddCharacter});

  final Future<WorkspaceProjection> initial;
  final Future<WorkspaceProjection?> Function(String novelWorkspaceId)?
  onTapAddCharacter;

  @override
  State<_CardBody> createState() => _CardBodyState();
}

class _CardBodyState extends State<_CardBody> {
  late Future<WorkspaceProjection> _current = widget.initial;
  WorkspaceProjection? _lastData;
  bool _linking = false;
  String? _error;

  @override
  void didUpdateWidget(covariant _CardBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initial != oldWidget.initial) {
      _current = widget.initial;
      _lastData = null;
    }
  }

  Future<void> _addLink() async {
    final action = widget.onTapAddCharacter;
    final novelId = _lastData?.novelWorkspaceId;
    if (action == null || novelId == null || _linking) return;
    setState(() {
      _linking = true;
      _error = null;
    });
    try {
      final refreshed = await action(novelId);
      if (!mounted) return;
      setState(() {
        _linking = false;
        if (refreshed != null) {
          _lastData = refreshed;
          _current = Future<WorkspaceProjection>.value(refreshed);
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _linking = false;
        _error = 'Unable to add character link.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<WorkspaceProjection>(
    future: _current,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const _ProjectionState(
          title: 'Linked Characters',
          message: 'Loading linked characters…',
        );
      }
      if (snapshot.hasError) {
        return const _ProjectionState(
          title: 'Linked Characters',
          message: 'Unable to load linked characters.',
        );
      }
      final projection = snapshot.data;
      if (projection != null) _lastData = projection;
      final links = projection?.links ?? const [];
      final novelId = projection?.novelWorkspaceId;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Linked Characters',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              if (widget.onTapAddCharacter != null && novelId != null)
                IconButton(
                  tooltip: 'Link character',
                  // Guard re-entry tanpa animasi tanpa hujung: animasi
                  // berkelanjutan membuat pumpAndSettle (test maupun
                  // framework) tidak pernah settle.
                  onPressed: _linking ? null : _addLink,
                  icon: const Icon(Icons.person_add_alt),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.onTapAddCharacter == null && links.isEmpty)
            const Text('Select or create a character to link it here.'),
          if (links.isEmpty && widget.onTapAddCharacter != null)
            const Text('No linked characters'),
          if (links.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: links.length,
              separatorBuilder: (_, _) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final link = links[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.person_outline, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${link.characterId} · ${link.role}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              },
            ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ],
      );
    },
  );
}

class _ProjectionState extends StatelessWidget {
  const _ProjectionState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
      Text(message),
    ],
  );
}
