import 'package:flutter/material.dart';

import '../domain/reference_models.dart';

class ReferenceManagementScreen extends StatelessWidget {
  const ReferenceManagementScreen({
    super.key,
    required this.ownerAssetId,
    this.sets = const [],
    this.locks = const [],
    this.rules = const [],
    this.reviews = const [],
    this.onCreateSet,
    this.onCreateLock,
    this.onCreateRule,
    this.initialTab = 0,
  });

  final String ownerAssetId;
  final List<ReferenceSetModel> sets;
  final List<PreservationLockModel> locks;
  final List<ConsistencyRuleModel> rules;
  final List<ConsistencyReviewModel> reviews;
  final VoidCallback? onCreateSet;
  final VoidCallback? onCreateLock;
  final VoidCallback? onCreateRule;
  final int initialTab;

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 4,
    initialIndex: initialTab,
    child: Scaffold(
      appBar: AppBar(
        title: Text('Identity Consistency • $ownerAssetId'),
        bottom: const TabBar(
          isScrollable: true,
          tabs: [
            Tab(text: 'Reference Sets'),
            Tab(text: 'Identity Locks'),
            Tab(text: 'Consistency Rules'),
            Tab(text: 'Reports'),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          _EntityList(
            empty: 'No reference sets',
            actionLabel: 'Create Set',
            onAction: onCreateSet,
            children: sets
                .map(
                  (set) => ListTile(
                    leading: const Icon(Icons.collections_bookmark_outlined),
                    title: Text(set.name),
                    subtitle: Text('${set.referenceIds.length} references'),
                    trailing: set.defaultSet
                        ? const Chip(label: Text('DEFAULT'))
                        : null,
                  ),
                )
                .toList(growable: false),
          ),
          _EntityList(
            empty: 'No identity locks',
            actionLabel: 'Add Lock',
            onAction: onCreateLock,
            children: locks
                .map(
                  (lock) => SwitchListTile(
                    value: lock.enabled,
                    onChanged: null,
                    title: Text(lock.type.name),
                    subtitle: Text(lock.instruction),
                    secondary: CircleAvatar(child: Text('${lock.priority}')),
                  ),
                )
                .toList(growable: false),
          ),
          _EntityList(
            empty: 'No consistency rules',
            actionLabel: 'Add Rule',
            onAction: onCreateRule,
            children: rules
                .map(
                  (rule) => ListTile(
                    leading: Icon(
                      rule.severity == ConsistencySeverity.critical
                          ? Icons.error_outline
                          : Icons.rule,
                    ),
                    title: Text(rule.description),
                    subtitle: Text('${rule.type.name} • ${rule.severity.name}'),
                  ),
                )
                .toList(growable: false),
          ),
          _EntityList(
            empty: 'No consistency reports',
            actionLabel: null,
            children: reviews
                .map(
                  (review) => ListTile(
                    leading: Icon(_statusIcon(review.status)),
                    title: Text(review.status.name),
                    subtitle: Text(review.notes),
                    trailing: Text(review.generationOutputId),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    ),
  );

  static IconData _statusIcon(ConsistencyReviewStatus status) =>
      switch (status) {
        ConsistencyReviewStatus.passed => Icons.check_circle_outline,
        ConsistencyReviewStatus.failed => Icons.cancel_outlined,
        ConsistencyReviewStatus.reviewRequired => Icons.rate_review_outlined,
        ConsistencyReviewStatus.notReviewed => Icons.help_outline,
      };
}

class _EntityList extends StatelessWidget {
  const _EntityList({
    required this.empty,
    required this.actionLabel,
    required this.children,
    this.onAction,
  });
  final String empty;
  final String? actionLabel;
  final List<Widget> children;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => ListView(
      padding: EdgeInsets.all(constraints.maxWidth < 600 ? 12 : 24),
      children: [
        if (actionLabel != null)
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add),
              label: Text(actionLabel!),
            ),
          ),
        const SizedBox(height: 12),
        if (children.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(empty),
            ),
          )
        else
          ...children.map((child) => Card(child: child)),
      ],
    ),
  );
}
