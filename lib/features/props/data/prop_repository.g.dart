// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prop_repository.dart';

// ignore_for_file: type=lint
mixin _$PropRepositoryMixin on DatabaseAccessor<ProjectDatabase> {
  $PropsTable get props => attachedDatabase.props;
  $PropSpecificationsTable get propSpecifications =>
      attachedDatabase.propSpecifications;
  $PropStatesTable get propStates => attachedDatabase.propStates;
  PropRepositoryManager get managers => PropRepositoryManager(this);
}

class PropRepositoryManager {
  final _$PropRepositoryMixin _db;
  PropRepositoryManager(this._db);
  $$PropsTableTableManager get props =>
      $$PropsTableTableManager(_db.attachedDatabase, _db.props);
  $$PropSpecificationsTableTableManager get propSpecifications =>
      $$PropSpecificationsTableTableManager(
        _db.attachedDatabase,
        _db.propSpecifications,
      );
  $$PropStatesTableTableManager get propStates =>
      $$PropStatesTableTableManager(_db.attachedDatabase, _db.propStates);
}
