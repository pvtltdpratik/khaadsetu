import 'package:drift/drift.dart';

/// The mutable half of the inventory feature — the item catalog itself
/// stays a static in-memory list (nothing ever changes it), but a restock
/// request is a real operation that needs to survive a restart.
@DataClassName('RestockRequestRow')
class RestockRequestsTable extends Table {
  TextColumn get id => text()();
  TextColumn get itemId => text()();
  TextColumn get itemName => text()();
  IntColumn get requestedQuantity => integer()();
  TextColumn get status => text()(); // RestockRequestStatus.name
  DateTimeColumn get requestedDate => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
