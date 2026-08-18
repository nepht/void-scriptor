enum CanonStatus { canonical, nonCanonical, disputed, deprecated }

CanonStatus canonStatusFromJson(Object? value) => CanonStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => CanonStatus.canonical,
    );
