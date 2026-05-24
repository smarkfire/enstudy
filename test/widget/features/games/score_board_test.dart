import 'package:flutter_test/flutter_test.dart';
import 'package:enstudy/features/games/presentation/widgets/score_board.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('ScoreBoard组件', () {
    group('渲染得分', () {
      testWidgets('显示当前得分', (tester) async {
        await tester.pumpApp(
          const ScoreBoard(score: 150, streak: 0, timeRemaining: 60),
        );

        expect(find.text('150'), findsOneWidget);
      });

      testWidgets('显示得分标签', (tester) async {
        await tester.pumpApp(
          const ScoreBoard(score: 150, streak: 0, timeRemaining: 60),
        );

        expect(find.text('得分'), findsOneWidget);
      });
    });

    group('渲染连击数', () {
      testWidgets('显示当前连击数', (tester) async {
        await tester.pumpApp(
          const ScoreBoard(score: 0, streak: 5, timeRemaining: 60),
        );

        expect(find.text('5'), findsOneWidget);
      });

      testWidgets('显示连击标签', (tester) async {
        await tester.pumpApp(
          const ScoreBoard(score: 0, streak: 5, timeRemaining: 60),
        );

        expect(find.text('连击'), findsOneWidget);
      });
    });

    group('渲染剩余时间', () {
      testWidgets('显示格式化的剩余时间', (tester) async {
        await tester.pumpApp(
          const ScoreBoard(score: 0, streak: 0, timeRemaining: 90),
        );

        expect(find.text('01:30'), findsOneWidget);
      });

      testWidgets('显示剩余标签', (tester) async {
        await tester.pumpApp(
          const ScoreBoard(score: 0, streak: 0, timeRemaining: 90),
        );

        expect(find.text('剩余'), findsOneWidget);
      });

      testWidgets('不足一分钟时显示正确格式', (tester) async {
        await tester.pumpApp(
          const ScoreBoard(score: 0, streak: 0, timeRemaining: 45),
        );

        expect(find.text('00:45'), findsOneWidget);
      });

      testWidgets('时间为0时显示00:00', (tester) async {
        await tester.pumpApp(
          const ScoreBoard(score: 0, streak: 0, timeRemaining: 0),
        );

        expect(find.text('00:00'), findsOneWidget);
      });
    });
  });
}
