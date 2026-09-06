enum ContentModuleMaturity { full, partial, domainOnly, uiOnly, planned }

extension ContentModuleMaturityLabel on ContentModuleMaturity {
  String get label => switch (this) {
    ContentModuleMaturity.full => 'Full',
    ContentModuleMaturity.partial => 'Partial',
    ContentModuleMaturity.domainOnly => 'Domain Only',
    ContentModuleMaturity.uiOnly => 'UI Only',
    ContentModuleMaturity.planned => 'Planned',
  };
}

enum ContentCapabilityState { available, partial, missing }

extension ContentCapabilityStateLabel on ContentCapabilityState {
  String get label => switch (this) {
    ContentCapabilityState.available => 'Tersedia',
    ContentCapabilityState.partial => 'Sebagian',
    ContentCapabilityState.missing => 'Belum tersedia',
  };
}

enum ContentWorkflowCapability {
  browse,
  createEdit,
  persistence,
  searchFilter,
  relations,
  validation,
  media,
  revisionHistory,
  importExport,
  collaboration,
}

extension ContentWorkflowCapabilityLabel on ContentWorkflowCapability {
  String get label => switch (this) {
    ContentWorkflowCapability.browse => 'Daftar konten',
    ContentWorkflowCapability.createEdit => 'Buat & edit',
    ContentWorkflowCapability.persistence => 'Penyimpanan',
    ContentWorkflowCapability.searchFilter => 'Pencarian & filter',
    ContentWorkflowCapability.relations => 'Relasi konten',
    ContentWorkflowCapability.validation => 'Validasi',
    ContentWorkflowCapability.media => 'Media & lampiran',
    ContentWorkflowCapability.revisionHistory => 'Riwayat revisi',
    ContentWorkflowCapability.importExport => 'Import export',
    ContentWorkflowCapability.collaboration => 'Kolaborasi',
  };
}

class ContentModuleCapability {
  const ContentModuleCapability({
    required this.id,
    required this.label,
    required this.description,
    required this.maturity,
    required this.workflowStates,
    required this.nextAction,
    required this.evidence,
  });

  final String id;
  final String label;
  final String description;
  final ContentModuleMaturity maturity;
  final Map<ContentWorkflowCapability, ContentCapabilityState> workflowStates;
  final String nextAction;
  final List<String> evidence;

  int get availableCount => workflowStates.values
      .where((state) => state == ContentCapabilityState.available)
      .length;

  int get partialCount => workflowStates.values
      .where((state) => state == ContentCapabilityState.partial)
      .length;
}
