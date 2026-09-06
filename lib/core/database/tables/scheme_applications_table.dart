import 'package:drift/drift.dart';

/// One row per scheme the farmer has applied to. The scheme catalog itself
/// stays a static in-memory list; this is the one piece of state an
/// "Apply now" tap actually changes. [schemeId] is the primary key — at
/// most one application per scheme, matching the domain's own semantics.
@DataClassName('SchemeApplicationRow')
class SchemeApplicationsTable extends Table {
  TextColumn get schemeId => text()();
  TextColumn get status => text()(); // ApplicationStatus.name
  DateTimeColumn get appliedDate => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {schemeId};
}
