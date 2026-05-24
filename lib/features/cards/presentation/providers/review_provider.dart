import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:enstudy/core/database/app_database.dart';
import 'package:enstudy/core/database/daos/card_dao.dart';
import 'package:enstudy/core/database/daos/review_log_dao.dart';
import 'package:enstudy/core/utils/sm2_algorithm.dart';
import 'package:enstudy/features/cards/domain/entities/card.dart';
import 'package:enstudy/features/cards/data/models/card_model.dart';
import 'package:enstudy/features/upload/presentation/providers/upload_provider.dart';

final reviewLogDaoProvider = Provider<ReviewLogDao>((ref) {
  return ReviewLogDao(ref.watch(appDatabaseProvider));
});

class ReviewState {
  final List<Card> dueCards;
  final int currentIndex;
  final bool isCompleted;
  final int totalReviewed;
  final int correctCount;

  const ReviewState({
    this.dueCards = const [],
    this.currentIndex = 0,
    this.isCompleted = false,
    this.totalReviewed = 0,
    this.correctCount = 0,
  });

  ReviewState copyWith({
    List<Card>? dueCards,
    int? currentIndex,
    bool? isCompleted,
    int? totalReviewed,
    int? correctCount,
  }) {
    return ReviewState(
      dueCards: dueCards ?? this.dueCards,
      currentIndex: currentIndex ?? this.currentIndex,
      isCompleted: isCompleted ?? this.isCompleted,
      totalReviewed: totalReviewed ?? this.totalReviewed,
      correctCount: correctCount ?? this.correctCount,
    );
  }

  Card? get currentCard => dueCards.isNotEmpty && currentIndex < dueCards.length
      ? dueCards[currentIndex]
      : null;

  double get accuracy => totalReviewed > 0 ? correctCount / totalReviewed : 0.0;
}

class ReviewNotifier extends StateNotifier<ReviewState> {
  final CardDao _cardDao;
  final ReviewLogDao _reviewLogDao;
  final Sm2Algorithm _sm2 = Sm2Algorithm();
  final _uuid = const Uuid();

  ReviewNotifier(this._cardDao, this._reviewLogDao)
      : super(const ReviewState());

  Future<void> getDueCards() async {
    final cards = await _cardDao
        .getCardsDueForReview(DateTime.now().millisecondsSinceEpoch)
        .first;
    state = ReviewState(
      dueCards: cards.map((r) => r.toEntity()).toList(),
    );
  }

  Future<void> getNextReviewBatch({int count = 20}) async {
    final cards = await _cardDao
        .getCardsDueForReview(DateTime.now().millisecondsSinceEpoch)
        .first;
    final batch = cards.take(count).map((r) => r.toEntity()).toList();
    state = ReviewState(dueCards: batch);
  }

  Future<void> recordReview({
    required String cardId,
    required int quality,
    String? gameType,
  }) async {
    final cardRow = await _cardDao.getCardById(cardId);
    if (cardRow == null) return;

    final card = cardRow.toEntity();
    final result = _sm2.calculate(
      quality: quality,
      reviewCount: card.reviewCount,
      easeFactor: card.easeFactor,
      interval: card.interval,
    );

    final now = DateTime.now();
    final nextReview = now.add(Duration(days: result.newInterval.round()));
    final isCorrect = quality >= 3;

    final updatedCard = card.copyWith(
      reviewCount: card.reviewCount + 1,
      correctCount: card.correctCount + (isCorrect ? 1 : 0),
      nextReview: nextReview,
      interval: result.newInterval,
      easeFactor: result.newEaseFactor,
      status: result.newStatus,
    );

    await _cardDao.updateCard(updatedCard.toRow());

    await _reviewLogDao.insertLog(
      ReviewLogsCompanion(
        id: Value(_uuid.v4()),
        cardId: Value(cardId),
        quality: Value(quality),
        answeredAt: Value(now.millisecondsSinceEpoch),
        gameType: Value(gameType),
      ),
    );

    final newTotal = state.totalReviewed + 1;
    final newCorrect = state.correctCount + (isCorrect ? 1 : 0);
    final nextIndex = state.currentIndex + 1;
    final isCompleted = nextIndex >= state.dueCards.length;

    state = state.copyWith(
      currentIndex: nextIndex,
      totalReviewed: newTotal,
      correctCount: newCorrect,
      isCompleted: isCompleted,
    );
  }
}

final reviewProvider =
    StateNotifierProvider<ReviewNotifier, ReviewState>((ref) {
  return ReviewNotifier(
    CardDao(ref.watch(appDatabaseProvider)),
    ref.watch(reviewLogDaoProvider),
  );
});
