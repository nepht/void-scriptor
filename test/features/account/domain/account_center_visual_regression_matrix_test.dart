/// Sprint 115.52 — Visual Regression Matrix contract tests.
///
/// Locks the eleven canonical `required_matrix` cells of step 115.52 against
/// `sprint_115.json`, proves the contract is fail-closed, and grounds the
/// committed manifest in the live repository.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Size;

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_responsive_grid.dart';
import 'package:void_scriptor/features/account/domain/account_center_visual_regression_matrix.dart';

void main() {
  const canonicalSprintPath =
      'C:/Users/nepht/AppData/Local/hermes/references/void_scriptor/'
      'sprint_115.json';
  const canonicalSprintSha256 =
      'c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba';
  const matrixTestPath =
      'test/features/account/domain/'
      'account_center_visual_regression_matrix_test.dart';

  final manifestFile = File(
    'docs/planning/v1.2/sprint_115_visual_regression_matrix.json',
  );

  Map<String, dynamic> readManifest() {
    expect(manifestFile.existsSync(), isTrue, reason: '115.52 manifest');
    return jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
  }

  AccountVisualRegressionCell cell({
    String cell = '1536x1024',
    AccountVisualCellStatus status = AccountVisualCellStatus.pass,
    Set<AccountVisualRegressionAssertion> assertions = const {
      AccountVisualRegressionAssertion.renders,
    },
    List<String> measurements = const ['measured one thing'],
    String note = '',
  }) => AccountVisualRegressionCell(
    cell: cell,
    status: status,
    assertions: assertions,
    measurements: measurements,
    measured: measurements.length,
    note: note,
  );

  /// The assertion a canonical cell is expected to measure, so a synthetic
  /// pass row is never a bare "it rendered" rubber stamp.
  AccountVisualRegressionAssertion assertionFor(String name) => switch (name) {
    'themes' => AccountVisualRegressionAssertion.theme,
    '200_percent_scale' => AccountVisualRegressionAssertion.scaling,
    'long_text' => AccountVisualRegressionAssertion.longText,
    'missing_icon' => AccountVisualRegressionAssertion.missingIcon,
    'error_states' => AccountVisualRegressionAssertion.uiState,
    _ => AccountVisualRegressionAssertion.renders,
  };

  Map<String, AccountVisualRegressionCell> fullPassMatrix() =>
      <String, AccountVisualRegressionCell>{
        for (final name in AccountCenterVisualRegressionMatrix.requiredCells)
          name: cell(
            cell: name,
            assertions: <AccountVisualRegressionAssertion>{assertionFor(name)},
            measurements: <String>['synthetic measurement for $name'],
          ),
      };

  group('115.52 canonical cell set', () {
    test('locks the eleven canonical cells in spec order', () {
      expect(AccountCenterVisualRegressionMatrix.requiredCells, const <String>[
        '1536x1024',
        '1440',
        '1180',
        '900',
        '600',
        'mobile',
        'themes',
        '200_percent_scale',
        'long_text',
        'missing_icon',
        'error_states',
      ]);
    });

    test('matches required_matrix of step 115.52 in sprint_115.json', () {
      final file = File(canonicalSprintPath);
      expect(file.existsSync(), isTrue, reason: 'canonical sprint_115.json');
      expect(
        sha256.convert(file.readAsBytesSync()).toString(),
        canonicalSprintSha256,
        reason: 'canonical sprint hash drift',
      );
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final steps = document['steps'] as List<dynamic>;
      final step = steps.cast<Map<String, dynamic>>().firstWhere(
        (entry) => entry['id'] == '115.52',
      );
      expect(step['title'], 'Visual Regression Matrix');
      expect(
        step['required_matrix'],
        AccountCenterVisualRegressionMatrix.requiredCells,
        reason: 'required_matrix must be transcribed, not invented',
      );
    });

    test('rejects a cell outside the canonical set', () {
      expect(
        () => AccountCenterVisualRegressionMatrix.buildReport({
          ...fullPassMatrix(),
          'perf': cell(cell: 'perf'),
        }),
        throwsArgumentError,
      );
    });

    test('rejects a canonical cell that was never recorded', () {
      final incomplete = fullPassMatrix()..remove('long_text');
      expect(
        () => AccountCenterVisualRegressionMatrix.buildReport(incomplete),
        throwsStateError,
      );
    });

    test('rejects a row whose key does not match its cell', () {
      expect(
        () => AccountCenterVisualRegressionMatrix.buildReport({
          for (final name in AccountCenterVisualRegressionMatrix.requiredCells)
            name: cell(cell: name == 'mobile' ? 'missing_icon' : name),
        }),
        throwsArgumentError,
      );
    });
  });

  group('115.52 viewports come from live contracts', () {
    test('each size cell resolves to its own responsive tier', () {
      expect(
        AccountCenterVisualRegressionMatrix.viewportFor('1536x1024'),
        const Size(1536, 1024),
      );
      expect(
        AccountCenterVisualRegressionMatrix.tierFor('1536x1024'),
        AccountCenterLayoutTier.wideDesktop,
      );
      expect(
        AccountCenterVisualRegressionMatrix.tierFor('1440'),
        AccountCenterLayoutTier.wideDesktop,
      );
      expect(
        AccountCenterVisualRegressionMatrix.tierFor('1180'),
        AccountCenterLayoutTier.desktop,
      );
      expect(
        AccountCenterVisualRegressionMatrix.tierFor('900'),
        AccountCenterLayoutTier.compactDesktop,
      );
      expect(
        AccountCenterVisualRegressionMatrix.tierFor('600'),
        AccountCenterLayoutTier.tablet,
      );
      expect(
        AccountCenterVisualRegressionMatrix.tierFor('mobile'),
        AccountCenterLayoutTier.mobile,
      );
    });

    test('rejects a viewport request for a non-size cell', () {
      expect(
        () => AccountCenterVisualRegressionMatrix.viewportFor('themes'),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterVisualRegressionMatrix.viewportFor('nope'),
        throwsArgumentError,
      );
    });
  });

  group('115.52 fail-closed cell rules', () {
    test('rejects a pass with no measured assertion', () {
      expect(
        () => AccountCenterVisualRegressionMatrix.buildReport({
          ...fullPassMatrix(),
          'mobile': cell(
            cell: 'mobile',
            assertions: const {},
            measurements: const [],
          ),
        }),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterVisualRegressionMatrix.buildReport({
          ...fullPassMatrix(),
          'mobile': cell(cell: 'mobile', measurements: const []),
        }),
        throwsArgumentError,
      );
    });

    test(
      'rejects a measured count that disagrees with its measurement list',
      () {
        expect(
          () => AccountCenterVisualRegressionMatrix.buildReport({
            ...fullPassMatrix(),
            'long_text': const AccountVisualRegressionCell(
              cell: 'long_text',
              status: AccountVisualCellStatus.pass,
              assertions: {AccountVisualRegressionAssertion.longText},
              measurements: ['only one'],
              measured: 9,
            ),
          }),
          throwsArgumentError,
        );
      },
    );

    test('rejects an unnamed measurement', () {
      expect(
        () => AccountCenterVisualRegressionMatrix.buildReport({
          ...fullPassMatrix(),
          'long_text': cell(cell: 'long_text', measurements: const ['   ']),
        }),
        throwsArgumentError,
      );
    });

    test('rejects a fail that does not say what failed', () {
      expect(
        () => AccountCenterVisualRegressionMatrix.buildReport({
          ...fullPassMatrix(),
          'long_text': cell(
            cell: 'long_text',
            status: AccountVisualCellStatus.fail,
          ),
        }),
        throwsArgumentError,
      );
    });

    test('rejects a blocked cell with measurements or without a reason', () {
      expect(
        () => AccountCenterVisualRegressionMatrix.buildReport({
          ...fullPassMatrix(),
          'missing_icon': cell(
            cell: 'missing_icon',
            status: AccountVisualCellStatus.blocked,
          ),
        }),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterVisualRegressionMatrix.buildReport({
          ...fullPassMatrix(),
          'missing_icon': cell(
            cell: 'missing_icon',
            status: AccountVisualCellStatus.blocked,
            note: 'brand licensed marks are a legal review, not a local test.',
          ),
        }),
        throwsArgumentError,
      );
    });

    test('rejects a pending cell that claims measurements', () {
      expect(
        () => AccountCenterVisualRegressionMatrix.buildReport({
          ...fullPassMatrix(),
          'themes': cell(
            cell: 'themes',
            status: AccountVisualCellStatus.pending,
            measurements: const ['claims a run that never happened'],
          ),
        }),
        throwsArgumentError,
      );
    });
  });

  group('115.52 report verdict', () {
    test('a fully passing matrix is complete, passing, and ALL_PASS', () {
      final report = AccountCenterVisualRegressionMatrix.buildReport(
        fullPassMatrix(),
      );
      expect(report.isComplete, isTrue);
      expect(report.passCount, 11);
      expect(report.isPass, isTrue);
      expect(report.verdict, 'ALL_PASS');
    });

    test('a pending cell makes the matrix incomplete', () {
      final report = AccountCenterVisualRegressionMatrix.buildReport({
        ...fullPassMatrix(),
        'themes': cell(
          cell: 'themes',
          status: AccountVisualCellStatus.pending,
          assertions: const {},
          measurements: const [],
        ),
      });
      expect(report.isComplete, isFalse);
      expect(report.isPass, isFalse);
      expect(report.verdict, 'INCOMPLETE');
    });

    test('a failing cell keeps the matrix complete but not passing', () {
      final report = AccountCenterVisualRegressionMatrix.buildReport({
        ...fullPassMatrix(),
        'long_text': cell(
          cell: 'long_text',
          status: AccountVisualCellStatus.fail,
          note: 'A provider tile still overflows its row on the 900px tier.',
        ),
      });
      expect(report.isComplete, isTrue);
      expect(report.passCount, 10);
      expect(report.isPass, isFalse);
      expect(report.verdict, 'COMPLETE_10_OF_11_PASS');
      expect(report.statusOf('long_text'), AccountVisualCellStatus.fail);
    });
  });

  group('115.52 committed manifest', () {
    test('declares the step and carries the canonical cell list', () {
      final manifest = readManifest();
      expect(manifest['step'], '115.52');
      expect(manifest['title'], 'Visual Regression Matrix');
      expect(
        manifest['required_matrix'],
        AccountCenterVisualRegressionMatrix.requiredCells,
      );
    });

    test('records every canonical cell in order and passes buildReport', () {
      final manifest = readManifest();
      final cells = (manifest['cells'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(
        cells.map((entry) => entry['cell']),
        AccountCenterVisualRegressionMatrix.requiredCells,
        reason: 'cell rows must follow the canonical order, no extras',
      );
      final results = <String, AccountVisualRegressionCell>{
        for (final entry in cells)
          entry['cell'] as String: AccountVisualRegressionCell(
            cell: entry['cell'] as String,
            status: AccountVisualCellStatus.values.firstWhere(
              (status) => status.name == entry['status'],
              orElse: () => throw ArgumentError.value(
                entry['status'],
                'cells',
                'Unknown cell status in the committed manifest.',
              ),
            ),
            assertions: (entry['assertions'] as List<dynamic>)
                .cast<String>()
                .map(
                  (name) => AccountVisualRegressionAssertion.values.firstWhere(
                    (value) => value.name == name,
                    orElse: () => throw ArgumentError.value(
                      name,
                      'cells',
                      'Unknown assertion in the committed manifest.',
                    ),
                  ),
                )
                .toSet(),
            measurements: (entry['measurements'] as List<dynamic>)
                .cast<String>(),
            measured: (entry['measured'] as num).toInt(),
            note: (entry['note'] as String?) ?? '',
          ),
      };
      final report = AccountCenterVisualRegressionMatrix.buildReport(results);
      expect(
        report.isComplete,
        isTrue,
        reason: 'a committed matrix may never leave a cell pending',
      );
      expect(manifest['verdict'], report.verdict);
      expect(manifest['verdict'], isNot('INCOMPLETE'));
    });

    test('a cell that is not passing explains itself concretely', () {
      final manifest = readManifest();
      for (final entry
          in (manifest['cells'] as List<dynamic>)
              .cast<Map<String, dynamic>>()) {
        if (entry['status'] == 'pass') {
          expect(
            (entry['measured'] as num).toInt(),
            greaterThan(0),
            reason: '${entry['cell']} passed without measurements',
          );
          expect(
            (entry['measurements'] as List<dynamic>),
            isNotEmpty,
            reason: '${entry['cell']} must name what it measured',
          );
          continue;
        }
        expect(
          ((entry['note'] as String?) ?? '').length,
          greaterThanOrEqualTo(30),
          reason: '${entry['cell']} must state why it is not passing',
        );
      }
    });

    test('the manifest documents its own coverage', () {
      final manifest = readManifest();
      final evidence = (manifest['evidence'] as List<dynamic>).cast<String>();
      expect(
        evidence.any(
          (path) =>
              path == matrixTestPath || matrixTestPath.startsWith('$path/'),
        ),
        isTrue,
        reason: 'the matrix must document the tests that measured it',
      );
      for (final path in evidence) {
        final file = File(path);
        expect(
          file.existsSync(),
          isTrue,
          reason: 'evidence missing on disk: $path',
        );
        expect(
          file.readAsStringSync().contains('test(') ||
              file.readAsStringSync().contains('testWidgets('),
          isTrue,
          reason: 'evidence must be a real test file: $path',
        );
      }
    });

    test('external boundaries stay declared instead of silently passing', () {
      final manifest = readManifest();
      final deferred = (manifest['deferred_external'] as List<dynamic>)
          .cast<String>();
      expect(
        deferred.length,
        greaterThanOrEqualTo(4),
        reason: 'external gates must be listed, not dropped',
      );
      expect(
        deferred
            .map((item) => item.toLowerCase().replaceAll('-', ' '))
            .any((item) => item.contains('screen reader')),
        isTrue,
        reason: 'native screen-reader certification is a platform gate',
      );
      expect(
        (manifest['overlap_note'] as String? ?? '').isNotEmpty,
        isTrue,
        reason: 'cells overlap by design; the overlap must be stated',
      );
    });
  });
}
