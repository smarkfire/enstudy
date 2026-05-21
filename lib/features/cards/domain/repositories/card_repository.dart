import 'package:enstudy/features/cards/domain/entities/card.dart';

abstract class CardRepository {
  Stream<List<Card>> getCards();

  Future<Card?> getCardById(String id);

  Stream<List<Card>> getCardsByStatus(String status);

  Stream<List<Card>> getCardsDueForReview();

  Future<void> addCard(Card card);

  Future<void> addCards(List<Card> cards);

  Future<void> updateCard(Card card);

  Future<void> deleteCard(String id);

  Stream<List<Card>> searchCards(String query);

  Future<Map<String, int>> getCardCountByStatus();
}
