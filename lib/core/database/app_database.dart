import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/orders_table.dart';
import 'tables/restock_requests_table.dart';
import 'tables/scheme_applications_table.dart';

part 'app_database.g.dart';

/// The app's single local (on-device) database. Every feature that needs
/// local persistence adds a table here rather than opening its own database
/// — one file to look at for the whole on-device schema.
///
/// To add a feature's table: define a `Table` subclass under `tables/`,
/// list it in `@DriftDatabase(tables: [...])` below, bump [schemaVersion],
/// and add an `onUpgrade` step in [migration] that creates just the new
/// table(s) — anyone who already has an older database on disk needs that
/// step; a fresh install only ever hits `onCreate`. See
/// `features/operator/orders/data/datasources/orders_local_data_source.dart`
/// for the full read/write pattern against a table.
@DriftDatabase(tables: [OrdersTable, RestockRequestsTable, SchemeApplicationsTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(restockRequestsTable);
            await m.createTable(schemeApplicationsTable);
          }
        },
      );
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
