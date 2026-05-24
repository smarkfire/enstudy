import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:enstudy/core/constants/game_constants.dart';
import 'package:enstudy/core/database/app_database.dart';
import 'package:enstudy/core/database/daos/card_dao.dart';
import 'package:enstudy/core/database/daos/game_session_dao.dart';
import 'package:enstudy/core/database/daos/review_log_dao.dart';
import 'package:enstudy/core/utils/score_calculator.dart';
import 'package:enstudy/core/utils/sm2_algorithm.dart';
import 'package:enstudy/features/cards/data/models/card_model.dart';
import 'package:enstudy/features/cards/domain/entities/card.dart' as domain;
import 'package:enstudy/features/cards/presentation/providers/review_provider.dart';
import 'package:enstudy/features/games/domain/entities/game_type.dart';
import 'package:enstudy/features/upload/presentation/providers/upload_provider.dart';

class GameState {
  final GameType? gameType;
  final List<domain.Card> cards;
  final int score;
  final int totalQuestions;
  final int correctQuestions;
  final int currentQuestionIndex;
  final bool isCompleted;
  final int timeElapsed;
  final int streak;
  final List<domain.Card> wrongCards;
  final DateTime? startedAt;

  const GameState({
    this.gameType,
    this.cards = const [],
    this.score = 0,
    this.totalQuestions = 0,
    this.correctQuestions = 0,
    this.currentQuestionIndex = 0,
    this.isCompleted = false,
    this.timeElapsed = 0,
    this.streak = 0,
    this.wrongCards = const [],
    this.startedAt,
  });

  GameState copyWith({
    GameType? gameType,
    List<domain.Card>? cards,
    int? score,
    int? totalQuestions,
    int? correctQuestions,
    int? currentQuestionIndex,
    bool? isCompleted,
    int? timeElapsed,
    int? streak,
    List<domain.Card>? wrongCards,
    DateTime? startedAt,
  }) {
    return GameState(
      gameType: gameType ?? this.gameType,
      cards: cards ?? this.cards,
      score: score ?? this.score,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctQuestions: correctQuestions ?? this.correctQuestions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      isCompleted: isCompleted ?? this.isCompleted,
      timeElapsed: timeElapsed ?? this.timeElapsed,
      streak: streak ?? this.streak,
      wrongCards: wrongCards ?? this.wrongCards,
      startedAt: startedAt ?? this.startedAt,
    );
  }

  double get accuracy =>
      totalQuestions > 0 ? correctQuestions / totalQuestions : 0.0;

  int get timeRemaining {
    final limit = GameConstants.roundTimeLimit.inSeconds * totalQuestions;
    return (limit - timeElapsed).clamp(0, limit);
  }

  domain.Card? get currentCard =>
      cards.isNotEmpty && currentQuestionIndex < cards.length
          ? cards[currentQuestionIndex]
          : null;
}

class GameNotifier extends StateNotifier<GameState> {
  final CardDao _cardDao;
  final GameSessionDao _gameSessionDao;
  final ReviewLogDao _reviewLogDao;
  final Sm2Algorithm _sm2 = Sm2Algorithm();
  final ScoreCalculator _scoreCalculator = ScoreCalculator();
  final _uuid = const Uuid();
  Timer? _timer;

  GameNotifier(this._cardDao, this._gameSessionDao, this._reviewLogDao)
      : super(const GameState());

  Future<void> startGame(GameType gameType, List<domain.Card> cards) async {
    _timer?.cancel();
    final shuffled = List<domain.Card>.from(cards)..shuffle();
    final gameCards = shuffled.take(GameConstants.cardsPerRound).toList();

    state = GameState(
      gameType: gameType,
      cards: gameCards,
      totalQuestions: gameCards.length,
      startedAt: DateTime.now(),
      timeElapsed: 0,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.isCompleted) {
        state = state.copyWith(timeElapsed: state.timeElapsed + 1);
      }
    });
  }

  void answerCorrect() {
    final newStreak = state.streak + 1;
    final points = _scoreCalculator.calculateGameAnswer(
      isCorrect: true,
      streakCount: newStreak,
    );
    state = state.copyWith(
      score: state.score + points,
      correctQuestions: state.correctQuestions + 1,
      streak: newStreak,
      currentQuestionIndex: state.currentQuestionIndex + 1,
    );
    _checkCompletion();
  }

  void answerWrong() {
    const penalty = GameConstants.penaltyPerWrongAnswer;
    final newWrongCards = List<domain.Card>.from(state.wrongCards);
    if (state.currentCard != null) {
      newWrongCards.add(state.currentCard!);
    }
    state = state.copyWith(
      score: (state.score - penalty).clamp(0, state.score),
      streak: 0,
      wrongCards: newWrongCards,
      currentQuestionIndex: state.currentQuestionIndex + 1,
    );
    _checkCompletion();
  }

  void _checkCompletion() {
    if (state.currentQuestionIndex >= state.cards.length) {
      completeGame();
    }
  }

  Future<void> completeGame() async {
    _timer?.cancel();
    state = state.copyWith(isCompleted: true);

    if (state.gameType == null || state.startedAt == null) return;

    await _gameSessionDao.insertSession(
      GameSessionsCompanion(
        id: Value(_uuid.v4()),
        gameType: Value(state.gameType!.name),
        startedAt: Value(state.startedAt!.millisecondsSinceEpoch),
        endedAt: Value(DateTime.now().millisecondsSinceEpoch),
        score: Value(state.score),
        totalQuestions: Value(state.totalQuestions),
        correctQuestions: Value(state.correctQuestions),
      ),
    );

    for (final card in state.wrongCards) {
      final quality = mapGameResultToQuality(
        state.gameType!,
        false,
        0,
      );
      await _recordCardReview(card, quality);
    }

    final correctCards = state.cards
        .where((c) => !state.wrongCards.any((w) => w.id == c.id))
        .toList();
    for (final card in correctCards) {
      final quality = mapGameResultToQuality(
        state.gameType!,
        true,
        (state.timeElapsed * 1000) ~/ state.totalQuestions,
      );
      await _recordCardReview(card, quality);
    }
  }

  Future<void> _recordCardReview(domain.Card card, int quality) async {
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
        cardId: Value(card.id),
        quality: Value(quality),
        answeredAt: Value(now.millisecondsSinceEpoch),
        gameType: Value(state.gameType?.name),
      ),
    );
  }

  int mapGameResultToQuality(GameType gameType, bool isCorrect, int timeMs) {
    if (!isCorrect) {
      if (timeMs > 10000) return 0;
      return 1;
    }

    switch (gameType) {
      case GameType.match:
        if (timeMs < 3000) return 5;
        if (timeMs < 5000) return 4;
        return 3;
      case GameType.spell:
        if (timeMs < 5000) return 5;
        if (timeMs < 8000) return 4;
        return 3;
      case GameType.listen:
        if (timeMs < 3000) return 5;
        if (timeMs < 6000) return 4;
        return 3;
      case GameType.fillBlank:
        if (timeMs < 4000) return 5;
        if (timeMs < 7000) return 4;
        return 3;
      case GameType.speed:
        if (timeMs < 2000) return 5;
        if (timeMs < 4000) return 4;
        return 3;
      case GameType.reorder:
        if (timeMs < 5000) return 5;
        if (timeMs < 8000) return 4;
        return 3;
      case GameType.shooting:
        if (timeMs < 2000) return 5;
        if (timeMs < 4000) return 4;
        return 3;
      case GameType.whack:
        if (timeMs < 2000) return 5;
        if (timeMs < 4000) return 4;
        return 3;
    }
  }

  int getTimeRemaining() => state.timeRemaining;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final gameSessionDaoProvider = Provider<GameSessionDao>((ref) {
  return GameSessionDao(ref.watch(appDatabaseProvider));
});

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier(
    CardDao(ref.watch(appDatabaseProvider)),
    ref.watch(gameSessionDaoProvider),
    ref.watch(reviewLogDaoProvider),
  );
});
