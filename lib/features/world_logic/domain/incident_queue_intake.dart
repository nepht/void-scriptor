/// Local incident intake contract for Sprint 114.5.
///
/// This dependency-free model records operational metadata only. Creative
/// content, prompts, manuscripts, and secrets are outside the intake scope.
class IncidentRecord {
  const IncidentRecord({
    required this.incidentId,
    required this.source,
    required this.version,
    required this.impact,
    required this.scope,
    required this.reproduction,
    required this.evidence,
    required this.owner,
  });

  final String incidentId;
  final String source;
  final String version;
  final String impact;
  final String scope;
  final String reproduction;
  final List<String> evidence;
  final String owner;
}

enum IncidentQueueState { pass, fail, blocked }

class IncidentQueueDecision {
  const IncidentQueueDecision({
    required this.state,
    required this.incidentCount,
    required this.missingFields,
    required this.notes,
  });

  final IncidentQueueState state;
  final int incidentCount;
  final List<String> missingFields;
  final List<String> notes;
}

class IncidentQueue {
  final List<IncidentRecord> _records = <IncidentRecord>[];

  List<IncidentRecord> get records =>
      List<IncidentRecord>.unmodifiable(_records);

  void add(IncidentRecord record) => _records.add(record);

  IncidentQueueDecision evaluate() {
    if (_records.isEmpty) {
      return const IncidentQueueDecision(
        state: IncidentQueueState.blocked,
        incidentCount: 0,
        missingFields: <String>[],
        notes: <String>[
          'Belum ada incident nyata yang diterima; intake eksternal '
              'DEFERRED-EXTERNAL.',
        ],
      );
    }

    final missing = <String>[];
    for (final record in _records) {
      if (record.incidentId.trim().isEmpty) missing.add('incident_id');
      if (record.source.trim().isEmpty) missing.add('source');
      if (record.version.trim().isEmpty) missing.add('version');
      if (record.impact.trim().isEmpty) missing.add('impact');
      if (record.scope.trim().isEmpty) missing.add('scope');
      if (record.reproduction.trim().isEmpty) missing.add('reproduction');
      if (record.evidence.isEmpty) missing.add('evidence');
      if (record.owner.trim().isEmpty) missing.add('owner');
    }

    return IncidentQueueDecision(
      state: missing.isEmpty
          ? IncidentQueueState.pass
          : IncidentQueueState.fail,
      incidentCount: _records.length,
      missingFields: List<String>.unmodifiable(missing),
      notes: const <String>[
        'Intake menyimpan metadata incident dan referensi evidence saja; '
            'creative content dan secret tidak dikumpulkan.',
      ],
    );
  }
}
