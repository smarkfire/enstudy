import 'package:drift/drift.dart';
import '../app_database.dart';

part 'source_dao.g.dart';

@DriftAccessor(tables: [Sources])
class SourceDao extends DatabaseAccessor<AppDatabase> with _$SourceDaoMixin {
  SourceDao(super.db);

  Stream<List<SourceRow>> getAllSources() => select(sources).watch();

  Future<SourceRow?> getSourceById(String id) =>
      (select(sources)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> insertSource(Insertable<SourceRow> source) =>
      into(sources).insertOnConflictUpdate(source);

  Future<void> deleteSource(String id) =>
      (delete(sources)..where((t) => t.id.equals(id))).go();

  Stream<List<SourceRow>> getRecentSources({int limit = 10}) =>
      (select(sources)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])..limit(limit))
          .watch();
}
