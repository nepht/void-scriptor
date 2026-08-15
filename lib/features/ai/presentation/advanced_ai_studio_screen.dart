import 'package:flutter/material.dart';

import 'output_review_panel.dart';

/// Unified advanced AI studio surface (Step 28.22).
///
/// Composes the prompt composer, streaming output, review, and usage panels in
/// one workspace. Full wiring to provider/router/queue happens in the app
/// shell; this screen is the presentation host.
class AdvancedAiStudioScreen extends StatefulWidget {
  const AdvancedAiStudioScreen({super.key});

  @override
  State<AdvancedAiStudioScreen> createState() => _AdvancedAiStudioScreenState();
}

class _AdvancedAiStudioScreenState extends State<AdvancedAiStudioScreen> {
  final _promptController = TextEditingController();

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Advanced AI Studio')),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _promptController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  labelText: 'Prompt',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: _Section(title: 'Output', child: SizedBox()),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: _Section(
                    title: 'Review',
                    child: OutputReviewPanel(
                      onApprove: () {},
                      onReject: () {},
                      onFeedback: (_) {},
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                const Expanded(
                  child: _Section(title: 'Usage', child: SizedBox()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        Expanded(child: child),
      ],
    );
  }
}
