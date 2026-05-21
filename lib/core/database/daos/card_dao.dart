import 'package:drift/drift.dart';
import '../app_database.dart';

part 'card_dao.g.dart';

@DriftAccessor(tables: [Cards])
class CardDao extends DatabaseAccessor<AppDatabase> with _$CardDaoMixin {
  CardDao(super.db);

  Stream<List<CardRow>> getAllCards() => select(cards).watch();

  Future<CardRow?> getCardById(String id) =>
      (select(cards)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<List<CardRow>> getCardsByStatus(String status) =>
      (select(cards)..where((t) => t.status.equals(status))).watch();

  Stream<List<CardRow>> getCardsDueForReview(int timestamp) =>
      (select(cards)..where((t) => t.nextReview.isSmallerOrEqualValue(timestamp)))
          .watch();

  Future<void> insertCard(Insertable<CardRow> card) =>
      into(cards).insertOnConflictUpdate(card);

  Future<void> insertCards(List<Insertable<CardRow>> cardsList) =>
      batch((b) => b.insertAllOnConflictUpdate(cards, cardsList));

  Future<void> updateCard(CardRow card) => update(cards).replace(card);

  Future<void> deleteCard(String id) =>
      (delete(cards)..where((t) => t.id.equals(id))).go();

  Stream<List<CardRow>> searchCards(String query) =>
      (select(cards)..where((t) => t.content.like('%$query%') | t.translation.like('%$query%')))
          .watch();

  Future<Map<String, int>> getCardCountByStatus() async {
    final query = selectOnly(cards)
      ..addColumns([cards.status, cards.id.count()]);
    query.groupBy([cards.status]);
    final rows = await query.get();
    return {
      for (final row in rows)
        row.read(cards.status)!: row.read(cards.id.count())!
    };
  }
}
