import 'package:flutter/material.dart';

class ScaleComparisonItem {
  const ScaleComparisonItem({required this.name, required this.heightCm});
  final String name;
  final double heightCm;
}

class ScaleComparisonWidget extends StatelessWidget {
  const ScaleComparisonWidget({
    super.key,
    this.items = const [
      ScaleComparisonItem(name: 'Human', heightCm: 185),
      ScaleComparisonItem(name: 'Asset', heightCm: 190),
    ],
  });
  final List<ScaleComparisonItem> items;
  @override
  Widget build(BuildContext context) {
    final max = items.fold<double>(
      1,
      (value, item) => item.heightCm > value ? item.heightCm : value,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Scale Comparison',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final item in items)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: FractionallySizedBox(
                              heightFactor: item.heightCm / max,
                              child: Container(
                                width: 42,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(item.name, overflow: TextOverflow.ellipsis),
                          Text(
                            item.heightCm >= 1000
                                ? '${(item.heightCm / 100).toStringAsFixed(1)} m'
                                : '${item.heightCm.toStringAsFixed(0)} cm',
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
