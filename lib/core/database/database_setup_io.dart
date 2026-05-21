import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'package:enstudy/core/database/app_database.dart';

AppDatabase createDatabase() {
  return AppDatabase(_connect());
}

QueryExecutor _connect() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File('${dbFolder.path}/enstudy.db');
    return NativeDatabase.createInBackground(file);
  });
}
