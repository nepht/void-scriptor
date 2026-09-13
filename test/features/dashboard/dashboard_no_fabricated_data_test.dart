import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regression lock for vs-hunt-20260913-dashboard DB-BUG-04 (Referee:
/// "Wire to asset provider or remove stub").
///
/// The dashboard surface must never render fabricated asset names. A project
/// with no assets must not show 'Qowner' / 'Void Coat' / 'Dual Dagger' tiles,
/// and no dead widget holding invented data may linger in the dashboard tree.
void main() {
  final dashboardLib = Directory('lib/features/dashboard');

  test(
    'DB-BUG-04: no fabricated recent-asset labels anywhere in dashboard lib',
    () {
      expect(
        dashboardLib.existsSync(),
        isTrue,
        reason: 'dashboard region must exist for this guard to be meaningful',
      );
      final offenders = <String>[];
      for (final file
          in dashboardLib.listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;
        final content = file.readAsStringSync();
        for (final needle in const ['Qowner', 'Void Coat', 'Dual Dagger']) {
          if (content.contains(needle)) {
            offenders.add('${file.path}:$needle');
          }
        }
      }
      expect(
        offenders,
        isEmpty,
        reason: 'dashboard must not carry hardcoded fake asset data',
      );
    },
  );

  test('DB-BUG-04: RecentAssets stub widget is removed from the codebase', () {
    final widgetFile = File(
      'lib/features/dashboard/presentation/widgets/recent_assets.dart',
    );
    expect(
      widgetFile.existsSync(),
      isFalse,
      reason: 'dead hardcoded RecentAssets stub must be deleted, not mounted',
    );
    // No dangling references may remain in the whole lib/ tree.
    final refs = <String>[];
    for (final file in Directory(
      'lib',
    ).listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final content = file.readAsStringSync();
      if (content.contains('RecentAssets') ||
          content.contains('recent_assets.dart')) {
        refs.add(file.path);
      }
    }
    expect(refs, isEmpty, reason: 'dangling RecentAssets references: $refs');
  });
}
