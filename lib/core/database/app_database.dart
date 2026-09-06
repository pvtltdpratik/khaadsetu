import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/orders_table.dart';

part 'app_database.g.dart';

/// The app's single local (on-device) database. Every feature that needs
/// local persistence adds a table here rather than opening its own database
/// — one file to look at for the whole on-device schema.
///
/// To add a feature's table: define a `Table` subclass under `tables/`,
/// list it in `@DriftDatabase(tables: [...])` below, bump [schemaVersion],
/// and add a migration step in [migration]. See
/// `features/operator/orders/data/datasources/orders_local_data_source.dart`
/// for the full read/write pattern against a table.
@DriftDatabase(tables: [OrdersTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy();
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'khaadsetu',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}
