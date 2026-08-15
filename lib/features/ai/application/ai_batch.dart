import 'dart:async';

import '../domain/ai_provider.dart';

class AiBatchItem {
  const AiBatchItem({required this.prompt, required this.target});
  final String prompt;
  final PromptTarget target;
}

class AiBatchResult {
  const AiBatchResult({
    required this.item,
    required this.success,
    this.output,
    this.error,
  });
  final AiBatchItem item;
  final bool success;
  final AiGenerationResult? output;
  final String? error;
}

/// Runs a list of prompts against a provider with bounded concurrency
/// (Step 28.13–28.14). Partial failures are surfaced per item, not thrown.
class AiBatchExecutor {
  AiBatchExecutor({required this.provider, this.maxConcurrent = 2})
    : assert(maxConcurrent > 0);

  final AiProvider provider;
  final int maxConcurrent;

  Future<List<AiBatchResult>> run(List<AiBatchItem> items) async {
    final results = <AiBatchResult>[];
    var index = 0;

    Future<void> worker() async {
      while (index < items.length) {
        final itemIndex = index++;
        final item = items[itemIndex];
        try {
          final output = await provider.generate(
            AiGenerationRequest(
              jobId: 'batch-$itemIndex',
              prompt: item.prompt,
              target: item.target,
            ),
          );
          results.add(AiBatchResult(item: item, success: true, output: output));
        } catch (error) {
          results.add(
            AiBatchResult(item: item, success: false, error: error.toString()),
          );
        }
      }
    }

    final workers = List.generate(
      maxConcurrent.clamp(1, items.length),
      (_) => worker(),
    );
    await Future.wait(workers);

    // Preserve input order.
    results.sort((a, b) => items.indexOf(a.item) - items.indexOf(b.item));
    return results;
  }
}
