import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/incident_queue_intake.dart';

void main() {
  group('114.5 Incident Queue Intake', () {
    test(
      'empty queue is blocked rather than claiming incidents were reviewed',
      () {
        final decision = IncidentQueue().evaluate();

        expect(decision.state, IncidentQueueState.blocked);
        expect(decision.incidentCount, 0);
        expect(
          decision.notes,
          anyElement(contains('Belum ada incident nyata')),
        );
      },
    );

    test('incomplete incident reports every missing canonical field', () {
      final queue = IncidentQueue()
        ..add(
          const IncidentRecord(
            incidentId: 'INC-001',
            source: '',
            version: '1.2.0-rc.1',
            impact: '',
            scope: 'local project open',
            reproduction: '',
            evidence: <String>[],
            owner: '',
          ),
        );

      final decision = queue.evaluate();

      expect(decision.state, IncidentQueueState.fail);
      expect(decision.missingFields, <String>[
        'source',
        'impact',
        'reproduction',
        'evidence',
        'owner',
      ]);
    });

    test(
      'complete incident is retained without collecting creative content',
      () {
        final queue = IncidentQueue()
          ..add(
            const IncidentRecord(
              incidentId: 'INC-002',
              source: 'local_support',
              version: '1.2.0-rc.1',
              impact: 'project_open_blocked',
              scope: 'project-open workflow',
              reproduction: 'open the documented fixture once',
              evidence: <String>['docs/evidence/inc-002.log'],
              owner: 'core-maintainer',
            ),
          );

        final decision = queue.evaluate();

        expect(decision.state, IncidentQueueState.pass);
        expect(decision.incidentCount, 1);
        expect(decision.missingFields, isEmpty);
        expect(queue.records.single.evidence, <String>[
          'docs/evidence/inc-002.log',
        ]);
      },
    );

    test(
      'manifest declares the eight canonical intake fields and local limits',
      () {
        final file = File(
          'docs/planning/v1.2/sprint_114_incident_queue_intake.json',
        );
        expect(file.existsSync(), isTrue);
        final document =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

        expect(document['canonical_step'], '114.5');
        expect(document['required_fields'], <dynamic>[
          'incident_id',
          'source',
          'version',
          'impact',
          'scope',
          'reproduction',
          'evidence',
          'owner',
        ]);
        expect(document['content_collection'], 'excluded');
        expect(document['external_intake'], 'DEFERRED-EXTERNAL');
      },
    );
  });
}
