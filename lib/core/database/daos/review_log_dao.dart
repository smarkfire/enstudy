import 'package:drift/drift.dart';
import '../app_database.dart';

part 'review_log_dao.g.dart';

@DriftAccessor(tables: [ReviewLogs])
class ReviewLogDao extends DatabaseAccessor<AppDatabase>
    with _$ReviewLogDaoMixin {
  ReviewLogDao(super.db);

  Stream<List<ReviewLogRow>> getAllLogs() => select(reviewLogs).watch();

  Stream<List<ReviewLogRow>> getLogsByCardId(String cardId) =>
      (select(reviewLogs)..where((t) => t.cardId.equals(cardId))).watch();

  Future<void> insertLog(Insertable<ReviewLogRow> log) =>
      into(reviewLogs).insert(log);

  Stream<List<ReviewLogRow>> getLogsByDateRange(int start, int end) =>
      (select(reviewLogs)
            ..where((t) =>
                t.answeredAt.isBiggerOrEqualValue(start) &
                t.answeredAt.isSmallerOrEqualValue(end)))
          .watch();
}
