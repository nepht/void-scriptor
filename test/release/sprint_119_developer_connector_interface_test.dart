import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/application/sprint_119_developer_connector_interface.dart';

void main() {
  final org = OrgRef.tryParse('orgref:acme:platform')!;
  final otherOrg = OrgRef.tryParse('orgref:beta:labs')!;
  final repoRef = ResourceRef.tryParse('resref:acme:checkout-service')!;
  final issueRef = ResourceRef.tryParse('resref:acme:tracker')!;

  final repo = DeveloperResource(
    ref: repoRef,
    kind: DeveloperResourceKind.repository,
    organization: org,
    declaredScopes: const <DeveloperScope>{
      DeveloperScope.read,
      DeveloperScope.write,
    },
  );
  final readOnlyIssue = DeveloperResource(
    ref: issueRef,
    kind: DeveloperResourceKind.issue,
    organization: org,
    declaredScopes: const <DeveloperScope>{DeveloperScope.read},
  );
  final foreignResource = DeveloperResource(
    ref: ResourceRef.tryParse('resref:beta:secret-repo')!,
    kind: DeveloperResourceKind.repository,
    organization: otherOrg,
    declaredScopes: const <DeveloperScope>{
      DeveloperScope.read,
      DeveloperScope.write,
      DeveloperScope.admin,
    },
  );

  group('119.15 Developer Connector Interface', () {
    test(
      'organization and resource references are opaque and malformed ones rejected',
      () {
        expect(org.value, 'orgref:acme:platform');
        expect(org.toString(), '[REDACTED]');
        expect(repoRef.value, 'resref:acme:checkout-service');
        expect(repoRef.toString(), '[REDACTED]');
        expect(OrgRef.tryParse('acme/platform'), isNull);
        expect(ResourceRef.tryParse('orgref:acme:platform'), isNull);
        expect(OrgRef.tryParse('orgref:acme:platform'), org);
      },
    );

    test('listOrganizations deduplicates and sorts deterministically', () {
      final listed =
          DeveloperConnectorInterface.listOrganizations(<DeveloperOrganization>[
            DeveloperOrganization(ref: org, tier: 'team'),
            DeveloperOrganization(ref: otherOrg, tier: 'free'),
            DeveloperOrganization(ref: org, tier: 'team'),
          ]);

      expect(listed, hasLength(2));
      expect(listed.map((o) => o.ref.value).toList(), <String>[
        'orgref:acme:platform',
        'orgref:beta:labs',
      ]);
    });

    test('listResources filters by organization and required scope', () {
      final resources = <DeveloperResource>[
        repo,
        readOnlyIssue,
        foreignResource,
      ];

      expect(
        DeveloperConnectorInterface.listResources(
          resources,
          organization: org,
          scope: DeveloperScope.write,
        ).map((r) => r.ref.value).toList(),
        <String>['resref:acme:checkout-service'],
      );
      expect(
        DeveloperConnectorInterface.listResources(
          resources,
          organization: org,
          scope: DeveloperScope.read,
        ),
        hasLength(2),
      );
      expect(
        DeveloperConnectorInterface.listResources(
          resources,
          organization: otherOrg,
          scope: DeveloperScope.admin,
        ),
        hasLength(1),
      );
    });

    test('read is denied without caller scope and without resource scope', () {
      expect(
        DeveloperConnectorInterface.read(
          resource: repo,
          organization: org,
          callerScopes: const <DeveloperScope>{},
        ),
        DeveloperOperationResult.deniedMissingScope,
      );
      expect(
        DeveloperConnectorInterface.read(
          resource: null,
          organization: org,
          callerScopes: const <DeveloperScope>{DeveloperScope.read},
        ),
        DeveloperOperationResult.deniedUnknownResource,
      );
      expect(
        DeveloperConnectorInterface.read(
          resource: foreignResource,
          organization: org,
          callerScopes: const <DeveloperScope>{DeveloperScope.read},
        ),
        DeveloperOperationResult.deniedUnknownOrganization,
      );
      expect(
        DeveloperConnectorInterface.read(
          resource: repo,
          organization: org,
          callerScopes: const <DeveloperScope>{DeveloperScope.read},
        ),
        DeveloperOperationResult.ok,
      );
    });

    test(
      'write_when_granted is denied without write scope and read never implies write',
      () {
        expect(
          DeveloperConnectorInterface.writeWhenGranted(
            resource: repo,
            organization: org,
            callerScopes: const <DeveloperScope>{DeveloperScope.read},
          ),
          DeveloperOperationResult.deniedMissingScope,
        );
        expect(
          DeveloperConnectorInterface.writeWhenGranted(
            resource: readOnlyIssue,
            organization: org,
            callerScopes: const <DeveloperScope>{
              DeveloperScope.read,
              DeveloperScope.write,
            },
          ),
          DeveloperOperationResult.deniedMissingScope,
        );
        expect(
          DeveloperConnectorInterface.writeWhenGranted(
            resource: repo,
            organization: org,
            callerScopes: const <DeveloperScope>{DeveloperScope.write},
          ),
          DeveloperOperationResult.ok,
        );
      },
    );

    test('an authorized write produces an append-only ordered audit entry', () {
      final trail = DeveloperAuditTrail();
      final result = DeveloperConnectorInterface.writeWhenGranted(
        resource: repo,
        organization: org,
        callerScopes: const <DeveloperScope>{DeveloperScope.write},
      );
      trail.append(
        action: 'write',
        target: repo.ref,
        allowed: result == DeveloperOperationResult.ok,
        at: DateTime.utc(2026, 3, 1, 12),
      );
      trail.append(
        action: 'read',
        target: issueRef,
        allowed: false,
        at: DateTime.utc(2026, 3, 1, 12, 1),
      );

      expect(trail.entries, hasLength(2));
      expect(trail.entries.map((e) => e.sequence).toList(), <int>[1, 2]);
      expect(trail.entries.first.allowed, isTrue);
      expect(trail.isOrdered, isTrue);
      expect(trail.entries.first.toJson()['target'], '[REDACTED]');
      expect(
        () => trail.entries.add(trail.entries.first),
        throwsUnsupportedError,
      );
    });

    test('rate limits are validated and non-negative', () {
      const limits = DeveloperLimits(
        requestsPerMinute: 60,
        requestsPerPeriod: 5000,
        period: Duration(days: 1),
        isEstimate: true,
      );
      expect(DeveloperConnectorInterface.validateLimits(limits), isEmpty);
      expect(
        DeveloperConnectorInterface.validateLimits(
          const DeveloperLimits(
            requestsPerMinute: -1,
            requestsPerPeriod: 5000,
            period: Duration(days: 1),
            isEstimate: false,
          ),
        ),
        contains('requests_per_minute_negative'),
      );
      expect(
        DeveloperConnectorInterface.validateLimits(
          const DeveloperLimits(
            requestsPerMinute: 60,
            requestsPerPeriod: 0,
            period: Duration.zero,
            isEstimate: false,
          ),
        ),
        contains('period_not_positive'),
      );
    });

    test('limit checks fail closed on negative or exhausted usage', () {
      expect(
        DeveloperConnectorInterface.isWithinLimits(used: 10, limit: 60),
        isTrue,
      );
      expect(
        DeveloperConnectorInterface.isWithinLimits(used: 60, limit: 60),
        isFalse,
      );
      expect(
        DeveloperConnectorInterface.isWithinLimits(used: 61, limit: 60),
        isFalse,
      );
      expect(
        DeveloperConnectorInterface.isWithinLimits(used: -1, limit: 60),
        isFalse,
      );
      expect(
        DeveloperConnectorInterface.isWithinLimits(used: 10, limit: 0),
        isFalse,
      );
    });

    test('health reports unavailable, degraded, and ok deterministically', () {
      expect(
        DeveloperConnectorInterface.health(
          reachable: false,
          authorized: true,
          withinLimits: true,
        ),
        DeveloperHealth.unavailable,
      );
      expect(
        DeveloperConnectorInterface.health(
          reachable: true,
          authorized: false,
          withinLimits: true,
        ),
        DeveloperHealth.degraded,
      );
      expect(
        DeveloperConnectorInterface.health(
          reachable: true,
          authorized: true,
          withinLimits: true,
        ),
        DeveloperHealth.ok,
      );
    });

    test('diagnostics redact organization and resource references', () {
      expect(
        DeveloperConnectorInterface.redact(
          'denied orgref:acme:platform resref:acme:tracker',
        ),
        'denied [REDACTED] [REDACTED]',
      );
    });

    test('validates the canonical manifest and rejects missing methods', () {
      expect(DeveloperConnectorInterface.validateCanonicalManifest(), isEmpty);

      final missing = <String, dynamic>{
        'canonical_step': '119.15',
        'unknown_field_policy': 'REJECT',
        'required_methods': <String>['list_organizations'],
        'acceptance': <String, dynamic>{},
      };
      expect(
        DeveloperConnectorInterface.validateManifest(missing),
        containsAll(<String>[
          'method_missing:write_when_granted',
          'method_missing:limits',
          'method_missing:health',
          'acceptance_missing:read',
        ]),
      );
    });
  });
}
