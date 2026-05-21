import 'package:flutter_test/flutter_test.dart';
import 'package:enstudy/core/utils/score_calculator.dart';
import 'package:enstudy/core/constants/game_constants.dart';

void main() {
  late ScoreCalculator calculator;

  setUp(() {
    calculator = ScoreCalculator();
  });

  group('积分计算器', () {
    group('每日打卡积分', () {
      test('返回正确的打卡积分', () {
        final result = calculator.calculateDailyCheckin();

        expect(result, GameConstants.pointsPerReview * 5);
      });
    });

    group('游戏答题积分', () {
      test('正确答题获得积分', () {
        final result = calculator.calculateGameAnswer(isCorrect: true);

        expect(result, GameConstants.pointsPerCorrectAnswer);
      });

      test('错误答题扣除积分', () {
        final result = calculator.calculateGameAnswer(isCorrect: false);

        expect(result, -GameConstants.penaltyPerWrongAnswer);
      });

      test('正确答题且达到连击阈值时获得额外加成', () {
        final result = calculator.calculateGameAnswer(
          isCorrect: true,
          streakCount: GameConstants.streakBonusThreshold,
        );

        expect(
            result, GameConstants.pointsPerCorrectAnswer + GameConstants.pointsPerStreak);
      });

      test('正确答题但未达到连击阈值时无额外加成', () {
        final result = calculator.calculateGameAnswer(
          isCorrect: true,
          streakCount: GameConstants.streakBonusThreshold - 1,
        );

        expect(result, GameConstants.pointsPerCorrectAnswer);
      });
    });

    group('连击加成', () {
      test('连续5题加成', () {
        final result = calculator.calculateStreakBonus(5);

        expect(result, GameConstants.pointsPerStreak * 1);
      });

      test('连续10题加成', () {
        final result = calculator.calculateStreakBonus(10);

        expect(result, GameConstants.pointsPerStreak * 3);
      });

      test('连击达到最大倍数后不再增加', () {
        final result = calculator.calculateStreakBonus(30);

        expect(result, GameConstants.pointsPerStreak * GameConstants.maxStreakMultiplier);
      });

      test('刚好达到连击阈值时获得基础加成', () {
        final result =
            calculator.calculateStreakBonus(GameConstants.streakBonusThreshold);

        expect(result, GameConstants.pointsPerStreak);
      });
    });

    group('完美通关', () {
      test('完美通关加成包含所有正确答题积分和最大连击加成', () {
        final totalQuestions = 10;
        final result = calculator.calculatePerfectGame(totalQuestions);

        expect(
          result,
          GameConstants.pointsPerCorrectAnswer * totalQuestions +
              GameConstants.pointsPerStreak * GameConstants.maxStreakMultiplier,
        );
      });
    });

    group('复习积分', () {
      test('正确复习获得积分', () {
        final result = calculator.calculateReviewScore(isCorrect: true);

        expect(result, GameConstants.pointsPerReview);
      });

      test('错误复习不扣分', () {
        final result = calculator.calculateReviewScore(isCorrect: false);

        expect(result, 0);
      });
    });

    group('等级判定', () {
      test('0分为等级1（beginner）', () {
        expect(calculator.calculateLevelFromScore(0), 1);
      });

      test('100分为等级2（elementary）', () {
        expect(calculator.calculateLevelFromScore(100), 2);
      });

      test('500分为等级3（intermediate）', () {
        expect(calculator.calculateLevelFromScore(500), 3);
      });

      test('1500分为等级4（upper_intermediate）', () {
        expect(calculator.calculateLevelFromScore(1500), 4);
      });

      test('3000分为等级5（advanced）', () {
        expect(calculator.calculateLevelFromScore(3000), 5);
      });

      test('6000分为等级6（expert）', () {
        expect(calculator.calculateLevelFromScore(6000), 6);
      });

      test('介于阈值之间的分数对应正确等级', () {
        expect(calculator.calculateLevelFromScore(50), 1);
        expect(calculator.calculateLevelFromScore(300), 2);
        expect(calculator.calculateLevelFromScore(1000), 3);
        expect(calculator.calculateLevelFromScore(2000), 4);
        expect(calculator.calculateLevelFromScore(4500), 5);
      });

      test('超过最高阈值仍为最高等级', () {
        expect(calculator.calculateLevelFromScore(10000), 6);
      });
    });
  });
}
