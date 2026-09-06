import 'package:drift/drift.dart';

/// One row per order. Line items are stored as JSON in [itemsJson] rather
/// than a second joined table — they're always read and written as a single
/// unit together with their order, so a real join would add complexity
/// without buying anything. [type]/[status] store the domain enum's `.name`
/// as plain text, decoded back via `.values.byName(...)` in the data source
/// — explicit, and visible in one place, rather than a converter/codegen
/// mechanism that hides the mapping.
@DataClassName('OrderRow')
class OrdersTable extends Table {
  TextColumn get id => text()();
  TextColumn get customerName => text()();
  TextColumn get type => text()();
  TextColumn get status => text()();
  TextColumn get itemsJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get pickupOtp => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
