String? dateToJson(DateTime? value) => value?.toIso8601String();
DateTime? dateFromJson(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

List<String> stringsFromJson(Object? value) =>
    (value as List? ?? const []).map((item) => item.toString()).toList();

Map<String, dynamic> mapFromJson(Object? value) =>
    Map<String, dynamic>.from(value as Map? ?? const {});
