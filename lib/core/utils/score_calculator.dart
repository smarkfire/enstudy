import 'package:enstudy/core/constants/game_constants.dart';

class ScoreCalculator {
  int calculateDailyCheckin() => GameConstants.pointsPerReview * 5;

  int calculateGameAnswer({required bool isCorrect, int streakCount = 0}) {
    if (!isCorrect) return -GameConstants.penaltyPerWrongAnswer;
    int score = GameConstants.pointsPerCorrectAnswer;
    if (streakCount >= GameConstants.streakBonusThreshold) {
      score += calculateStreakBonus(streakCount);
    }
    return score;
  }

  int calculateStreakBonus(int streakCount) {
    final multiplier = (streakCount ~/ GameConstants.streakBonusThreshold)
        .clamp(1, GameConstants.maxStreakMultiplier);
    return GameConstants.pointsPerStreak * multiplier;
  }

  int calculatePerfectGame(int totalQuestions) {
    return GameConstants.pointsPerCorrectAnswer * totalQuestions +
        GameConstants.pointsPerStreak * GameConstants.maxStreakMultiplier;
  }

  int calculateReviewScore({required bool isCorrect}) {
    return isCorrect ? GameConstants.pointsPerReview : 0;
  }

  int calculateLevelFromScore(int totalScore) {
    final thresholds = GameConstants.levelThresholds.values.toList()..sort();
    int level = 1;
    for (int i = 0; i < thresholds.length; i++) {
      if (totalScore >= thresholds[i]) {
        level = i + 1;
      }
    }
    return level;
  }
}
