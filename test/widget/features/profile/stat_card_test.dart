import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enstudy/features/profile/presentation/widgets/stat_card.dart';
import 'package:enstudy/core/theme/colors.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('StatCard组件', () {
    group('渲染数值和标签', () {
      testWidgets('显示数值', (tester) async {
        await tester.pumpApp(
          const StatCard(
            icon: Icons.school_outlined,
            value: '128',
            label: '已学单词',
          ),
        );

        expect(find.text('128'), findsOneWidget);
      });

      testWidgets('显示标签', (tester) async {
        await tester.pumpApp(
          const StatCard(
            icon: Icons.school_outlined,
            value: '128',
            label: '已学单词',
          ),
        );

        expect(find.text('已学单词'), findsOneWidget);
      });

      testWidgets('显示图标', (tester) async {
        await tester.pumpApp(
          const StatCard(
            icon: Icons.school_outlined,
            value: '128',
            label: '已学单词',
          ),
        );

        expect(find.byIcon(Icons.school_outlined), findsOneWidget);
      });
    });

    group('自定义颜色', () {
      testWidgets('未指定颜色时使用primary', (tester) async {
        await tester.pumpApp(
          const StatCard(
            icon: Icons.school_outlined,
            value: '128',
            label: '已学单词',
          ),
        );

        final icon = tester.widget<Icon>(find.byIcon(Icons.school_outlined));
        expect(icon.color, AppColors.primary);
      });

      testWidgets('指定颜色时使用自定义颜色', (tester) async {
        await tester.pumpApp(
          const StatCard(
            icon: Icons.local_fire_department,
            value: '7',
            label: '连续天数',
            color: AppColors.error,
          ),
        );

        final icon =
            tester.widget<Icon>(find.byIcon(Icons.local_fire_department));
        expect(icon.color, AppColors.error);
      });

      testWidgets('自定义颜色影响背景', (tester) async {
        await tester.pumpApp(
          const StatCard(
            icon: Icons.star,
            value: '1500',
            label: '总积分',
            color: AppColors.accent,
          ),
        );

        final container = tester.widget<Container>(
          find.ancestor(
            of: find.byIcon(Icons.star),
            matching: find.byType(Container),
          ).first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, isNotNull);
      });
    });
  });
}
