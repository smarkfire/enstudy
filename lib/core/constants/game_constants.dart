class GameConstants {
  GameConstants._();

  static const int pointsPerCorrectAnswer = 10;
  static const int pointsPerStreak = 5;
  static const int pointsPerReview = 3;
  static const int penaltyPerWrongAnswer = 2;

  static const int streakBonusThreshold = 3;
  static const int maxStreakMultiplier = 5;

  static const Map<String, int> levelThresholds = {
    'beginner': 0,
    'elementary': 100,
    'intermediate': 500,
    'upper_intermediate': 1500,
    'advanced': 3000,
    'expert': 6000,
  };

  static const int dailyGoalDefault = 20;
  static const int dailyGoalMin = 5;
  static const int dailyGoalMax = 100;

  static const int cardsPerRound = 10;
  static const Duration roundTimeLimit = Duration(seconds: 30);
  static const Duration gameAnimationDuration = Duration(milliseconds: 500);

  static const double masteryThreshold = 0.85;
  static const int reviewIntervalEasy = 4;
  static const int reviewIntervalMedium = 2;
  static const int reviewIntervalHard = 1;
}
