import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enstudy/features/cards/presentation/widgets/card_list_item.dart';
import 'package:enstudy/features/cards/domain/entities/card.dart' as domain;

import '../../../helpers/pump_app.dart';

void main() {
  group('CardListItem组件', () {
    domain.Card createCard({
      String content = 'abandon',
      String translation = '放弃；抛弃',
      String status = 'new',
      int reviewCount = 0,
      int correctCount = 0,
    }) {
      return domain.Card(
        id: 'test-card',
        type: 'word',
        content: content,
        translation: translation,
        createdAt: DateTime(2024, 1, 1),
        nextReview: DateTime(2024, 1, 2),
        reviewCount: reviewCount,
        correctCount: correctCount,
        status: status,
      );
    }

    group('渲染content和translation', () {
      testWidgets('显示单词内容', (tester) async {
        final card = createCard(content: 'ephemeral');
        await tester.pumpApp(CardListItem(card: card));

        expect(find.text('ephemeral'), findsOneWidget);
      });

      testWidgets('显示翻译', (tester) async {
        final card = createCard(translation: '短暂的；转瞬即逝的');
        await tester.pumpApp(CardListItem(card: card));

        expect(find.text('短暂的；转瞬即逝的'), findsOneWidget);
      });
    });

    group('渲染状态标签', () {
      testWidgets('new状态显示"新学"', (tester) async {
        final card = createCard(status: 'new');
        await tester.pumpApp(CardListItem(card: card));

        expect(find.text('新学'), findsOneWidget);
      });

      testWidgets('review状态显示"待复习"', (tester) async {
        final card = createCard(status: 'review');
        await tester.pumpApp(CardListItem(card: card));

        expect(find.text('待复习'), findsOneWidget);
      });

      testWidgets('learning状态显示"学习中"', (tester) async {
        final card = createCard(status: 'learning');
        await tester.pumpApp(CardListItem(card: card));

        expect(find.text('学习中'), findsOneWidget);
      });

      testWidgets('mastered状态显示"已掌握"', (tester) async {
        final card = createCard(status: 'mastered');
        await tester.pumpApp(CardListItem(card: card));

        expect(find.text('已掌握'), findsOneWidget);
      });
    });

    group('渲染进度条', () {
      testWidgets('reviewCount为0时进度为0%', (tester) async {
        final card = createCard(reviewCount: 0, correctCount: 0);
        await tester.pumpApp(CardListItem(card: card));

        expect(find.text('0%'), findsOneWidget);
        final progressBar = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(progressBar.value, 0.0);
      });

      testWidgets('正确率80%时显示80%', (tester) async {
        final card = createCard(reviewCount: 10, correctCount: 8);
        await tester.pumpApp(CardListItem(card: card));

        expect(find.text('80%'), findsOneWidget);
        final progressBar = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(progressBar.value, closeTo(0.8, 0.01));
      });

      testWidgets('显示复习次数', (tester) async {
        final card = createCard(reviewCount: 5);
        await tester.pumpApp(CardListItem(card: card));

        expect(find.text('5次'), findsOneWidget);
      });
    });
  });
}
