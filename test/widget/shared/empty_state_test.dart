import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enstudy/shared/widgets/empty_state.dart';
import 'package:enstudy/core/theme/colors.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('EmptyState组件', () {
    group('默认消息显示', () {
      testWidgets('显示标题文本', (tester) async {
        await tester.pumpApp(
          const EmptyState(
            icon: Icons.inbox_outlined,
            title: '暂无内容',
          ),
        );

        expect(find.text('暂无内容'), findsOneWidget);
      });

      testWidgets('不显示副标题', (tester) async {
        await tester.pumpApp(
          const EmptyState(
            icon: Icons.inbox_outlined,
            title: '暂无内容',
          ),
        );

        final subtitleFinder = find.byType(Text);
        expect(subtitleFinder, findsOneWidget);
      });
    });

    group('自定义消息显示', () {
      testWidgets('显示自定义副标题', (tester) async {
        await tester.pumpApp(
          const EmptyState(
            icon: Icons.inbox_outlined,
            title: '暂无内容',
            subtitle: '点击下方按钮添加',
          ),
        );

        expect(find.text('暂无内容'), findsOneWidget);
        expect(find.text('点击下方按钮添加'), findsOneWidget);
      });

      testWidgets('显示操作按钮', (tester) async {
        await tester.pumpApp(
          const EmptyState(
            icon: Icons.inbox_outlined,
            title: '暂无内容',
            actionLabel: '添加',
            onAction: null,
          ),
        );

        expect(find.text('添加'), findsNothing);
      });

      testWidgets('操作按钮有回调时显示', (tester) async {
        var pressed = false;
        await tester.pumpApp(
          EmptyState(
            icon: Icons.inbox_outlined,
            title: '暂无内容',
            actionLabel: '添加',
            onAction: () {
              pressed = true;
            },
          ),
        );

        expect(find.text('添加'), findsOneWidget);

        await tester.tap(find.text('添加'));
        expect(pressed, isTrue);
      });
    });

    group('图标显示', () {
      testWidgets('显示指定图标', (tester) async {
        await tester.pumpApp(
          const EmptyState(
            icon: Icons.inbox_outlined,
            title: '暂无内容',
          ),
        );

        expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
      });

      testWidgets('图标大小为64', (tester) async {
        await tester.pumpApp(
          const EmptyState(
            icon: Icons.inbox_outlined,
            title: '暂无内容',
          ),
        );

        final icon = tester.widget<Icon>(find.byIcon(Icons.inbox_outlined));
        expect(icon.size, 64);
      });

      testWidgets('图标颜色为textHint', (tester) async {
        await tester.pumpApp(
          const EmptyState(
            icon: Icons.inbox_outlined,
            title: '暂无内容',
          ),
        );

        final icon = tester.widget<Icon>(find.byIcon(Icons.inbox_outlined));
        expect(icon.color, AppColors.textHint);
      });
    });
  });
}
