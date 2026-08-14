import 'package:flutter/material.dart';

class ProjectResilienceCenterScreen extends StatelessWidget {
  const ProjectResilienceCenterScreen({
    super.key,
    required this.title,
    required this.items,
    this.onAction,
  });
  final String title;
  final List<String> items;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 900 ? 3 : 1;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Project resilience',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: columns == 1 ? 4.5 : 2.2,
                children: [
                  for (final item in items)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.verified_outlined),
                        title: Text(item),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh),
                label: const Text('Scan Again'),
              ),
            ],
          );
        },
      ),
    );
  }
}
