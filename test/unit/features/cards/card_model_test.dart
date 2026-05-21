import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:enstudy/core/database/app_database.dart';
import 'package:enstudy/features/cards/data/models/card_model.dart';
import 'package:enstudy/features/cards/domain/entities/card.dart' as domain;

void main() {
  group('Card数据模型转换', () {
    group('tags的JSON序列化/反序列化', () {
      test('List<String>序列化为JSON字符串', () {
        final tags = ['CET4', 'CET6', 'IELTS'];
        final json = jsonEncode(tags);

        expect(json, '["CET4","CET6","IELTS"]');
      });

      test('JSON字符串反序列化为List<String>', () {
        const json = '["CET4","CET6","IELTS"]';
        final tags = (jsonDecode(json) as List).cast<String>();

        expect(tags, ['CET4', 'CET6', 'IELTS']);
      });

      test('空列表序列化为空数组', () {
        final tags = <String>[];
        final json = jsonEncode(tags);

        expect(json, '[]');
      });

      test('空数组反序列化为空列表', () {
        const json = '[]';
        final tags = (jsonDecode(json) as List).cast<String>();

        expect(tags, isEmpty);
      });

      test('tags往返转换一致', () {
        final tags = ['vocabulary', 'grammar', 'phrasal-verb'];
        final json = jsonEncode(tags);
        final decoded = (jsonDecode(json) as List).cast<String>();

        expect(decoded, equals(tags));
      });
    });

    group('DateTime与时间戳的转换', () {
      test('DateTime转换为毫秒时间戳', () {
        final dateTime = DateTime(2024, 6, 15, 10, 30, 0);
        final timestamp = dateTime.millisecondsSinceEpoch;

        expect(timestamp, isA<int>());
        expect(timestamp, greaterThan(0));
      });

      test('毫秒时间戳转换为DateTime', () {
        final dateTime = DateTime(2024, 6, 15, 10, 30, 0);
        final timestamp = dateTime.millisecondsSinceEpoch;
        final restored = DateTime.fromMillisecondsSinceEpoch(timestamp);

        expect(restored, dateTime);
      });

      test('DateTime往返转换一致', () {
        final original = DateTime(2024, 1, 1, 0, 0, 0);
        final timestamp = original.millisecondsSinceEpoch;
        final restored = DateTime.fromMillisecondsSinceEpoch(timestamp);

        expect(restored.year, original.year);
        expect(restored.month, original.month);
        expect(restored.day, original.day);
        expect(restored.hour, original.hour);
        expect(restored.minute, original.minute);
        expect(restored.second, original.second);
      });
    });

    group('CardRow到Card实体的转换', () {
      test('所有字段正确转换', () {
        final now = DateTime(2024, 6, 15);
        final row = CardRow(
          id: 'card-1',
          type: 'word',
          content: 'ephemeral',
          translation: '短暂的；转瞬即逝的',
          phonetic: '/ɪˈfemərəl/',
          example: 'The ephemeral beauty of cherry blossoms.',
          exampleTranslation: '樱花短暂的美丽。',
          sourceId: 'source-1',
          tags: jsonEncode(['GRE', 'SAT']),
          difficulty: 4,
          createdAt: now.millisecondsSinceEpoch,
          reviewCount: 5,
          correctCount: 3,
          nextReview: now.add(const Duration(days: 3)).millisecondsSinceEpoch,
          interval: 6.0,
          easeFactor: 2.36,
          status: 'review',
        );

        final entity = row.toEntity();

        expect(entity.id, 'card-1');
        expect(entity.type, 'word');
        expect(entity.content, 'ephemeral');
        expect(entity.translation, '短暂的；转瞬即逝的');
        expect(entity.phonetic, '/ɪˈfemərəl/');
        expect(entity.example, 'The ephemeral beauty of cherry blossoms.');
        expect(entity.exampleTranslation, '樱花短暂的美丽。');
        expect(entity.sourceId, 'source-1');
        expect(entity.tags, ['GRE', 'SAT']);
        expect(entity.difficulty, 4);
        expect(entity.createdAt, now);
        expect(entity.reviewCount, 5);
        expect(entity.correctCount, 3);
        expect(entity.interval, 6.0);
        expect(entity.easeFactor, 2.36);
        expect(entity.status, 'review');
      });

      test('nullable字段为null时正确转换', () {
        final now = DateTime(2024, 6, 15);
        final row = CardRow(
          id: 'card-2',
          type: 'word',
          content: 'ubiquitous',
          translation: '无处不在的',
          tags: '[]',
          difficulty: 3,
          createdAt: now.millisecondsSinceEpoch,
          reviewCount: 0,
          correctCount: 0,
          nextReview: now.millisecondsSinceEpoch,
          interval: 1.0,
          easeFactor: 2.5,
          status: 'new',
        );

        final entity = row.toEntity();

        expect(entity.phonetic, isNull);
        expect(entity.example, isNull);
        expect(entity.exampleTranslation, isNull);
        expect(entity.sourceId, isNull);
      });
    });

    group('Card实体到CardRow的转换', () {
      test('所有字段正确转换', () {
        final now = DateTime(2024, 6, 15);
        final entity = domain.Card(
          id: 'card-3',
          type: 'phrase',
          content: 'break through',
          translation: '突破；取得重大进展',
          phonetic: null,
          example: 'Scientists broke through a major barrier.',
          exampleTranslation: '科学家们突破了一个重大障碍。',
          sourceId: null,
          tags: ['phrasal-verb', 'CET6'],
          difficulty: 3,
          createdAt: now,
          reviewCount: 2,
          correctCount: 2,
          nextReview: now.add(const Duration(days: 6)),
          interval: 6.0,
          easeFactor: 2.5,
          status: 'review',
        );

        final row = entity.toRow();

        expect(row.id, 'card-3');
        expect(row.type, 'phrase');
        expect(row.content, 'break through');
        expect(row.translation, '突破；取得重大进展');
        expect(row.phonetic, isNull);
        expect(row.example, 'Scientists broke through a major barrier.');
        expect(row.exampleTranslation, '科学家们突破了一个重大障碍。');
        expect(row.sourceId, isNull);
        expect(jsonDecode(row.tags), ['phrasal-verb', 'CET6']);
        expect(row.difficulty, 3);
        expect(row.createdAt, now.millisecondsSinceEpoch);
        expect(row.reviewCount, 2);
        expect(row.correctCount, 2);
        expect(row.nextReview, now.add(const Duration(days: 6)).millisecondsSinceEpoch);
        expect(row.interval, 6.0);
        expect(row.easeFactor, 2.5);
        expect(row.status, 'review');
      });
    });

    group('往返转换的一致性', () {
      test('CardRow → Card → CardRow 往返一致', () {
        final now = DateTime(2024, 6, 15);
        final originalRow = CardRow(
          id: 'card-rt',
          type: 'word',
          content: 'resilient',
          translation: '有弹性的；能迅速恢复的',
          phonetic: '/rɪˈzɪliənt/',
          example: 'She is remarkably resilient.',
          exampleTranslation: '她非常坚韧。',
          sourceId: 'source-rt',
          tags: jsonEncode(['TOEFL', 'GRE']),
          difficulty: 5,
          createdAt: now.millisecondsSinceEpoch,
          reviewCount: 10,
          correctCount: 8,
          nextReview: now.add(const Duration(days: 15)).millisecondsSinceEpoch,
          interval: 15.0,
          easeFactor: 2.6,
          status: 'review',
        );

        final entity = originalRow.toEntity();
        final restoredRow = entity.toRow();

        expect(restoredRow.id, originalRow.id);
        expect(restoredRow.type, originalRow.type);
        expect(restoredRow.content, originalRow.content);
        expect(restoredRow.translation, originalRow.translation);
        expect(restoredRow.phonetic, originalRow.phonetic);
        expect(restoredRow.example, originalRow.example);
        expect(restoredRow.exampleTranslation, originalRow.exampleTranslation);
        expect(restoredRow.sourceId, originalRow.sourceId);
        expect(restoredRow.tags, originalRow.tags);
        expect(restoredRow.difficulty, originalRow.difficulty);
        expect(restoredRow.createdAt, originalRow.createdAt);
        expect(restoredRow.reviewCount, originalRow.reviewCount);
        expect(restoredRow.correctCount, originalRow.correctCount);
        expect(restoredRow.nextReview, originalRow.nextReview);
        expect(restoredRow.interval, originalRow.interval);
        expect(restoredRow.easeFactor, originalRow.easeFactor);
        expect(restoredRow.status, originalRow.status);
      });

      test('Card → CardRow → Card 往返一致', () {
        final now = DateTime(2024, 6, 15);
        final originalEntity = domain.Card(
          id: 'card-rt2',
          type: 'word',
          content: 'pragmatic',
          translation: '务实的；实用主义的',
          phonetic: '/præɡˈmætɪk/',
          example: 'She took a pragmatic approach to the problem.',
          exampleTranslation: '她对这个问题采取了务实的态度。',
          sourceId: 'source-rt2',
          tags: ['GRE', 'academic'],
          difficulty: 4,
          createdAt: now,
          reviewCount: 7,
          correctCount: 5,
          nextReview: now.add(const Duration(days: 10)),
          interval: 10.0,
          easeFactor: 2.45,
          status: 'review',
        );

        final row = originalEntity.toRow();
        final restoredEntity = row.toEntity();

        expect(restoredEntity.id, originalEntity.id);
        expect(restoredEntity.type, originalEntity.type);
        expect(restoredEntity.content, originalEntity.content);
        expect(restoredEntity.translation, originalEntity.translation);
        expect(restoredEntity.phonetic, originalEntity.phonetic);
        expect(restoredEntity.example, originalEntity.example);
        expect(restoredEntity.exampleTranslation, originalEntity.exampleTranslation);
        expect(restoredEntity.sourceId, originalEntity.sourceId);
        expect(restoredEntity.tags, originalEntity.tags);
        expect(restoredEntity.difficulty, originalEntity.difficulty);
        expect(restoredEntity.createdAt, originalEntity.createdAt);
        expect(restoredEntity.reviewCount, originalEntity.reviewCount);
        expect(restoredEntity.correctCount, originalEntity.correctCount);
        expect(restoredEntity.interval, originalEntity.interval);
        expect(restoredEntity.easeFactor, originalEntity.easeFactor);
        expect(restoredEntity.status, originalEntity.status);
      });
    });
  });
}
