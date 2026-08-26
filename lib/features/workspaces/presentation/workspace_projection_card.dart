import 'package:flutter/material.dart';

import '../application/workspace_projection_cache.dart';

class WorkspaceProjectionCard extends StatelessWidget {
  const WorkspaceProjectionCard({super.key, required this.projectionFuture});

  final Future<WorkspaceProjection> projectionFuture;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<WorkspaceProjection>(
        future: projectionFuture,
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
          final links = snapshot.data?.links ?? const [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Linked Characters',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (links.isEmpty)
                const Text('No linked characters')
              else
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
            ],
          );
        },
      ),
    ),
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
