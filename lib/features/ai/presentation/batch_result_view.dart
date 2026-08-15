import 'package:flutter/material.dart';

import '../application/ai_batch.dart';

/// Displays aggregated batch results with per-item status (Step 28.15).
class BatchResultView extends StatelessWidget {
  const BatchResultView({super.key, required this.results});

  final List<AiBatchResult> results;

  @override
  Widget build(BuildContext context) {
    final succeeded = results.where((r) => r.success).length;
    final failed = results.length - succeeded;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            '${results.length} items · $succeeded ok · $failed failed',
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              return ListTile(
                leading: Icon(
                  result.success ? Icons.check_circle : Icons.error,
                  color: result.success ? Colors.green : Colors.red,
                ),
                title: Text(
                  result.item.prompt,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: result.success ? null : Text(result.error ?? ''),
              );
            },
          ),
        ),
      ],
    );
  }
}
