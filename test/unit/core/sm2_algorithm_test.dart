import 'package:flutter_test/flutter_test.dart';
import 'package:enstudy/core/utils/sm2_algorithm.dart';

void main() {
  late Sm2Algorithm sm2;

  setUp(() {
    sm2 = Sm2Algorithm();
  });

  group('SM-2算法', () {
    group('quality=5（非常熟悉）', () {
      test('间隔应增长，easeFactor应增加', () {
        final result = sm2.calculate(
          quality: 5,
          reviewCount: 2,
          easeFactor: 2.5,
          interval: 6.0,
        );

        expect(result.newInterval, 6.0 * 2.5);
        expect(result.newEaseFactor, greaterThan(2.5));
        expect(result.newStatus, 'review');
      });

      test('easeFactor增加0.1', () {
        final result = sm2.calculate(
          quality: 5,
          reviewCount: 2,
          easeFactor: 2.5,
          interval: 6.0,
        );

        expect(result.newEaseFactor, closeTo(2.6, 0.001));
      });
    });

    group('quality=3（一定印象）', () {
      test('间隔按标准公式计算', () {
        final result = sm2.calculate(
          quality: 3,
          reviewCount: 2,
          easeFactor: 2.5,
          interval: 6.0,
        );

        expect(result.newInterval, 6.0 * 2.5);
        expect(result.newStatus, 'review');
      });

      test('easeFactor应减少', () {
        final result = sm2.calculate(
          quality: 3,
          reviewCount: 2,
          easeFactor: 2.5,
          interval: 6.0,
        );

        expect(result.newEaseFactor, lessThan(2.5));
        expect(result.newEaseFactor, closeTo(2.36, 0.001));
      });
    });

    group('quality=0（完全不认识）', () {
      test('间隔重置为1，状态变为learning', () {
        final result = sm2.calculate(
          quality: 0,
          reviewCount: 5,
          easeFactor: 2.5,
          interval: 30.0,
        );

        expect(result.newInterval, 1);
        expect(result.newStatus, 'learning');
      });

      test('easeFactor不变', () {
        final result = sm2.calculate(
          quality: 0,
          reviewCount: 5,
          easeFactor: 2.5,
          interval: 30.0,
        );

        expect(result.newEaseFactor, 2.5);
      });
    });

    group('quality=2（想起来了但费力）', () {
      test('间隔重置为1，状态变为learning', () {
        final result = sm2.calculate(
          quality: 2,
          reviewCount: 5,
          easeFactor: 2.5,
          interval: 30.0,
        );

        expect(result.newInterval, 1);
        expect(result.newStatus, 'learning');
      });

      test('easeFactor不变', () {
        final result = sm2.calculate(
          quality: 2,
          reviewCount: 5,
          easeFactor: 2.5,
          interval: 30.0,
        );

        expect(result.newEaseFactor, 2.5);
      });
    });

    group('easeFactor下限', () {
      test('easeFactor不低于1.3', () {
        final result = sm2.calculate(
          quality: 3,
          reviewCount: 0,
          easeFactor: 1.3,
          interval: 1.0,
        );

        expect(result.newEaseFactor, greaterThanOrEqualTo(1.3));
      });

      test('easeFactor从1.3减少后被限制为1.3', () {
        final result = sm2.calculate(
          quality: 3,
          reviewCount: 0,
          easeFactor: 1.3,
          interval: 1.0,
        );

        expect(result.newEaseFactor, 1.3);
      });

      test('easeFactor从1.4减少后被限制为1.3', () {
        final result = sm2.calculate(
          quality: 3,
          reviewCount: 0,
          easeFactor: 1.4,
          interval: 1.0,
        );

        expect(result.newEaseFactor, 1.3);
      });
    });

    group('首次复习（reviewCount=0）', () {
      test('间隔为1', () {
        final result = sm2.calculate(
          quality: 5,
          reviewCount: 0,
          easeFactor: 2.5,
          interval: 0,
        );

        expect(result.newInterval, 1);
      });

      test('quality=3首次复习间隔也为1', () {
        final result = sm2.calculate(
          quality: 3,
          reviewCount: 0,
          easeFactor: 2.5,
          interval: 0,
        );

        expect(result.newInterval, 1);
      });
    });

    group('第二次复习（reviewCount=1）', () {
      test('间隔为6', () {
        final result = sm2.calculate(
          quality: 5,
          reviewCount: 1,
          easeFactor: 2.5,
          interval: 1.0,
        );

        expect(result.newInterval, 6);
      });

      test('quality=4第二次复习间隔也为6', () {
        final result = sm2.calculate(
          quality: 4,
          reviewCount: 1,
          easeFactor: 2.5,
          interval: 1.0,
        );

        expect(result.newInterval, 6);
      });
    });

    group('后续复习（reviewCount>=2）', () {
      test('间隔 = interval * easeFactor', () {
        final result = sm2.calculate(
          quality: 5,
          reviewCount: 2,
          easeFactor: 2.5,
          interval: 6.0,
        );

        expect(result.newInterval, closeTo(6.0 * 2.5, 0.001));
      });

      test('不同easeFactor下的间隔计算', () {
        final result = sm2.calculate(
          quality: 4,
          reviewCount: 3,
          easeFactor: 3.0,
          interval: 15.0,
        );

        expect(result.newInterval, closeTo(15.0 * 3.0, 0.001));
      });
    });

    group('边界条件', () {
      test('quality=3是quality>=3的边界', () {
        final result3 = sm2.calculate(
          quality: 3,
          reviewCount: 2,
          easeFactor: 2.5,
          interval: 6.0,
        );

        expect(result3.newStatus, 'review');
      });

      test('quality=2是quality<3的边界', () {
        final result2 = sm2.calculate(
          quality: 2,
          reviewCount: 2,
          easeFactor: 2.5,
          interval: 6.0,
        );

        expect(result2.newStatus, 'learning');
        expect(result2.newInterval, 1);
      });

      test('quality=1也应重置间隔', () {
        final result = sm2.calculate(
          quality: 1,
          reviewCount: 2,
          easeFactor: 2.5,
          interval: 6.0,
        );

        expect(result.newInterval, 1);
        expect(result.newStatus, 'learning');
      });

      test('quality=4时easeFactor不变', () {
        final result = sm2.calculate(
          quality: 4,
          reviewCount: 2,
          easeFactor: 2.5,
          interval: 6.0,
        );

        expect(result.newEaseFactor, closeTo(2.5, 0.001));
      });

      test('非常大的interval', () {
        final result = sm2.calculate(
          quality: 5,
          reviewCount: 10,
          easeFactor: 2.5,
          interval: 365.0,
        );

        expect(result.newInterval, closeTo(365.0 * 2.5, 0.001));
      });

      test('非常大的easeFactor', () {
        final result = sm2.calculate(
          quality: 5,
          reviewCount: 5,
          easeFactor: 5.0,
          interval: 30.0,
        );

        expect(result.newInterval, closeTo(30.0 * 5.0, 0.001));
        expect(result.newEaseFactor, closeTo(5.1, 0.001));
      });

      test('quality=5时easeFactor增长最大', () {
        final result5 = sm2.calculate(
          quality: 5,
          reviewCount: 0,
          easeFactor: 2.5,
          interval: 1.0,
        );
        final result4 = sm2.calculate(
          quality: 4,
          reviewCount: 0,
          easeFactor: 2.5,
          interval: 1.0,
        );
        final result3 = sm2.calculate(
          quality: 3,
          reviewCount: 0,
          easeFactor: 2.5,
          interval: 1.0,
        );

        expect(result5.newEaseFactor, greaterThan(result4.newEaseFactor));
        expect(result4.newEaseFactor, greaterThan(result3.newEaseFactor));
      });

      test('连续多次quality=0后easeFactor仍不变', () {
        double easeFactor = 2.5;
        for (int i = 0; i < 10; i++) {
          final result = sm2.calculate(
            quality: 0,
            reviewCount: 5,
            easeFactor: easeFactor,
            interval: 30.0,
          );
          easeFactor = result.newEaseFactor;
        }

        expect(easeFactor, 2.5);
      });
    });
  });
}
