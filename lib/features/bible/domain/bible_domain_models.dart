import 'canon_status.dart';
import 'domain_helpers.dart';

abstract class _JsonModel {
  const _JsonModel();

  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) => other.runtimeType == runtimeType &&
      other is _JsonModel &&
      _mapsEqual(toJson(), other.toJson());

  @override
  int get hashCode => _mapHash(toJson());
}

bool _mapsEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!_valuesEqual(entry.value, b[entry.key])) return false;
  }
  return true;
}

bool _valuesEqual(Object? left, Object? right) {
  if (left is Map && right is Map) {
    return _mapsEqual(Map<String, dynamic>.from(left), Map<String, dynamic>.from(right));
  }
  if (left is List && right is List) {
    return left.length == right.length &&
        List.generate(left.length, (index) => _valuesEqual(left[index], right[index]))
            .every((matches) => matches);
  }
  return left == right;
}

int _mapHash(Map<String, dynamic> map) => map.entries.fold(0, (hash, entry) =>
    hash ^ Object.hash(entry.key, entry.value is List ? Object.hashAll(entry.value as List) : entry.value));

class FactionModel extends _JsonModel {
  final String id, name, description;
  final List<String> goals, members, territories, tags;
  final CanonStatus canonStatus;

  const FactionModel({required this.id, required this.name, this.description = '', this.goals = const [], this.members = const [], this.territories = const [], this.tags = const [], this.canonStatus = CanonStatus.canonical});
  factory FactionModel.fromJson(Map<String, dynamic> json) => FactionModel(id: json['id'] as String, name: json['name'] as String, description: json['description'] as String? ?? '', goals: stringsFromJson(json['goals']), members: stringsFromJson(json['members']), territories: stringsFromJson(json['territories']), tags: stringsFromJson(json['tags']), canonStatus: canonStatusFromJson(json['canonStatus']));
  @override Map<String, dynamic> toJson() => {'id': id, 'name': name, 'description': description, 'goals': goals, 'members': members, 'territories': territories, 'tags': tags, 'canonStatus': canonStatus.name};
}

class SpeciesModel extends _JsonModel {
  final String id, name, description;
  final List<String> traits, habitats, tags;
  final CanonStatus canonStatus;
  const SpeciesModel({required this.id, required this.name, this.description = '', this.traits = const [], this.habitats = const [], this.tags = const [], this.canonStatus = CanonStatus.canonical});
  factory SpeciesModel.fromJson(Map<String, dynamic> j) => SpeciesModel(id: j['id'] as String, name: j['name'] as String, description: j['description'] as String? ?? '', traits: stringsFromJson(j['traits']), habitats: stringsFromJson(j['habitats']), tags: stringsFromJson(j['tags']), canonStatus: canonStatusFromJson(j['canonStatus']));
  @override Map<String, dynamic> toJson() => {'id': id, 'name': name, 'description': description, 'traits': traits, 'habitats': habitats, 'tags': tags, 'canonStatus': canonStatus.name};
}

class TechnologyModel extends _JsonModel {
  final String id, name, description;
  final List<String> capabilities, prerequisites, tags;
  final CanonStatus canonStatus;
  const TechnologyModel({required this.id, required this.name, this.description = '', this.capabilities = const [], this.prerequisites = const [], this.tags = const [], this.canonStatus = CanonStatus.canonical});
  factory TechnologyModel.fromJson(Map<String, dynamic> j) => TechnologyModel(id: j['id'] as String, name: j['name'] as String, description: j['description'] as String? ?? '', capabilities: stringsFromJson(j['capabilities']), prerequisites: stringsFromJson(j['prerequisites']), tags: stringsFromJson(j['tags']), canonStatus: canonStatusFromJson(j['canonStatus']));
  @override Map<String, dynamic> toJson() => {'id': id, 'name': name, 'description': description, 'capabilities': capabilities, 'prerequisites': prerequisites, 'tags': tags, 'canonStatus': canonStatus.name};
}

class PowerSystemModel extends _JsonModel {
  final String id, name, description;
  final List<String> rules, limitations, tags;
  final CanonStatus canonStatus;
  const PowerSystemModel({required this.id, required this.name, this.description = '', this.rules = const [], this.limitations = const [], this.tags = const [], this.canonStatus = CanonStatus.canonical});
  factory PowerSystemModel.fromJson(Map<String, dynamic> j) => PowerSystemModel(id: j['id'] as String, name: j['name'] as String, description: j['description'] as String? ?? '', rules: stringsFromJson(j['rules']), limitations: stringsFromJson(j['limitations']), tags: stringsFromJson(j['tags']), canonStatus: canonStatusFromJson(j['canonStatus']));
  @override Map<String, dynamic> toJson() => {'id': id, 'name': name, 'description': description, 'rules': rules, 'limitations': limitations, 'tags': tags, 'canonStatus': canonStatus.name};
}

class PowerAbilityModel extends _JsonModel {
  final String id, name, powerSystemId, description;
  final List<String> effects, requirements, tags;
  final CanonStatus canonStatus;
  const PowerAbilityModel({required this.id, required this.name, required this.powerSystemId, this.description = '', this.effects = const [], this.requirements = const [], this.tags = const [], this.canonStatus = CanonStatus.canonical});
  factory PowerAbilityModel.fromJson(Map<String, dynamic> j) => PowerAbilityModel(id: j['id'] as String, name: j['name'] as String, powerSystemId: j['powerSystemId'] as String, description: j['description'] as String? ?? '', effects: stringsFromJson(j['effects']), requirements: stringsFromJson(j['requirements']), tags: stringsFromJson(j['tags']), canonStatus: canonStatusFromJson(j['canonStatus']));
  @override Map<String, dynamic> toJson() => {'id': id, 'name': name, 'powerSystemId': powerSystemId, 'description': description, 'effects': effects, 'requirements': requirements, 'tags': tags, 'canonStatus': canonStatus.name};
}

class TerminologyEntryModel extends _JsonModel {
  final String id, term, definition, description;
  final List<String> aliases, tags;
  final CanonStatus canonStatus;
  const TerminologyEntryModel({required this.id, required this.term, required this.definition, this.description = '', this.aliases = const [], this.tags = const [], this.canonStatus = CanonStatus.canonical});
  factory TerminologyEntryModel.fromJson(Map<String, dynamic> j) => TerminologyEntryModel(id: j['id'] as String, term: j['term'] as String, definition: j['definition'] as String, description: j['description'] as String? ?? '', aliases: stringsFromJson(j['aliases']), tags: stringsFromJson(j['tags']), canonStatus: canonStatusFromJson(j['canonStatus']));
  @override Map<String, dynamic> toJson() => {'id': id, 'term': term, 'definition': definition, 'description': description, 'aliases': aliases, 'tags': tags, 'canonStatus': canonStatus.name};
}

class TimelineEraModel extends _JsonModel {
  final String id, name, description;
  final DateTime? startDate, endDate;
  final List<String> tags;
  final CanonStatus canonStatus;
  const TimelineEraModel({required this.id, required this.name, this.description = '', this.startDate, this.endDate, this.tags = const [], this.canonStatus = CanonStatus.canonical});
  factory TimelineEraModel.fromJson(Map<String, dynamic> j) => TimelineEraModel(id: j['id'] as String, name: j['name'] as String, description: j['description'] as String? ?? '', startDate: dateFromJson(j['startDate']), endDate: dateFromJson(j['endDate']), tags: stringsFromJson(j['tags']), canonStatus: canonStatusFromJson(j['canonStatus']));
  @override Map<String, dynamic> toJson() => {'id': id, 'name': name, 'description': description, 'startDate': dateToJson(startDate), 'endDate': dateToJson(endDate), 'tags': tags, 'canonStatus': canonStatus.name};
}

class HistoricalEventParticipantModel extends _JsonModel {
  final String id, eventId, entityId, role;
  final String? entityType;
  const HistoricalEventParticipantModel({required this.id, required this.eventId, required this.entityId, required this.role, this.entityType});
  factory HistoricalEventParticipantModel.fromJson(Map<String, dynamic> j) => HistoricalEventParticipantModel(id: j['id'] as String, eventId: j['eventId'] as String, entityId: j['entityId'] as String, role: j['role'] as String, entityType: j['entityType'] as String?);
  @override Map<String, dynamic> toJson() => {'id': id, 'eventId': eventId, 'entityId': entityId, 'role': role, 'entityType': entityType};
}

class HistoricalEventModel extends _JsonModel {
  final String id, title, description;
  final DateTime? date;
  final String? eraId;
  final List<HistoricalEventParticipantModel> participants, tagsAsParticipants;
  final List<String> tags;
  final CanonStatus canonStatus;
  const HistoricalEventModel({required this.id, required this.title, this.description = '', this.date, this.eraId, this.participants = const [], this.tags = const [], this.tagsAsParticipants = const [], this.canonStatus = CanonStatus.canonical});
  factory HistoricalEventModel.fromJson(Map<String, dynamic> j) => HistoricalEventModel(id: j['id'] as String, title: j['title'] as String, description: j['description'] as String? ?? '', date: dateFromJson(j['date']), eraId: j['eraId'] as String?, participants: (j['participants'] as List? ?? const []).map((e) => HistoricalEventParticipantModel.fromJson(Map<String, dynamic>.from(e as Map))).toList(), tags: stringsFromJson(j['tags']), canonStatus: canonStatusFromJson(j['canonStatus']));
  @override Map<String, dynamic> toJson() => {'id': id, 'title': title, 'description': description, 'date': dateToJson(date), 'eraId': eraId, 'participants': participants.map((p) => p.toJson()).toList(), 'tags': tags, 'canonStatus': canonStatus.name};
}
