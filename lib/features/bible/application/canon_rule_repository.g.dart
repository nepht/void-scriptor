// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canon_rule_repository.dart';

// ignore_for_file: type=lint
mixin _$CanonRuleRepositoryMixin on DatabaseAccessor<ProjectDatabase> {
  $CanonRulesTable get canonRules => attachedDatabase.canonRules;
  $CanonRuleConditionsTable get canonRuleConditions =>
      attachedDatabase.canonRuleConditions;
  CanonRuleRepositoryManager get managers => CanonRuleRepositoryManager(this);
}

class CanonRuleRepositoryManager {
  final _$CanonRuleRepositoryMixin _db;
  CanonRuleRepositoryManager(this._db);
  $$CanonRulesTableTableManager get canonRules =>
      $$CanonRulesTableTableManager(_db.attachedDatabase, _db.canonRules);
  $$CanonRuleConditionsTableTableManager get canonRuleConditions =>
      $$CanonRuleConditionsTableTableManager(
        _db.attachedDatabase,
        _db.canonRuleConditions,
      );
}
