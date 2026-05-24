import 'package:enstudy/core/database/daos/card_dao.dart';
import 'package:enstudy/features/cards/data/models/card_model.dart';
import 'package:enstudy/features/cards/domain/entities/card.dart';
import 'package:enstudy/features/cards/domain/repositories/card_repository.dart';

class CardRepositoryImpl implements CardRepository {
  final CardDao _cardDao;

  CardRepositoryImpl(this._cardDao);

  @override
  Stream<List<Card>> getCards() => _cardDao
      .getAllCards()
      .map((rows) => rows.map((r) => r.toEntity()).toList());

  @override
  Future<Card?> getCardById(String id) async {
    final row = await _cardDao.getCardById(id);
    return row?.toEntity();
  }

  @override
  Stream<List<Card>> getCardsByStatus(String status) => _cardDao
      .getCardsByStatus(status)
      .map((rows) => rows.map((r) => r.toEntity()).toList());

  @override
  Stream<List<Card>> getCardsDueForReview() => _cardDao
      .getCardsDueForReview(DateTime.now().millisecondsSinceEpoch)
      .map((rows) => rows.map((r) => r.toEntity()).toList());

  @override
  Future<void> addCard(Card card) => _cardDao.insertCard(card.toCompanion());

  @override
  Future<void> addCards(List<Card> cards) =>
      _cardDao.insertCards(cards.map((c) => c.toCompanion()).toList());

  @override
  Future<void> updateCard(Card card) => _cardDao.updateCard(card.toRow());

  @override
  Future<void> deleteCard(String id) => _cardDao.deleteCard(id);

  @override
  Stream<List<Card>> searchCards(String query) => _cardDao
      .searchCards(query)
      .map((rows) => rows.map((r) => r.toEntity()).toList());

  @override
  Future<Map<String, int>> getCardCountByStatus() =>
      _cardDao.getCardCountByStatus();
}
