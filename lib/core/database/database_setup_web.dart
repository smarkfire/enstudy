import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

import 'package:enstudy/core/database/app_database.dart';

AppDatabase createDatabase() {
  return AppDatabase(_connect());
}

QueryExecutor _connect() {
  return DatabaseConnection.delayed(
    Future(() async {
      final result = await WasmDatabase.open(
        databaseName: 'enstudy',
        sqlite3Uri: Uri.parse('sqlite3.wasm'),
        driftWorkerUri: Uri.parse('drift_worker.js'),
      );

      if (result.missingFeatures.isNotEmpty) {
        print('Using ${result.chosenImplementation} due to missing browser '
            'features: ${result.missingFeatures}');
      }

      return result.resolvedExecutor;
    }),
  ).executor;
}
