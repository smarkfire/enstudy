import 'package:flutter_test/flutter_test.dart';
import 'package:enstudy/features/profile/data/models/export_data.dart';

void main() {
  group('导出数据模型', () {
    final testExportData = ExportData(
      version: '1.0',
      exportTime: '2024-06-15T10:30:00Z',
      appVersion: '1.0.0',
      cards: [
        {'id': 'card-1', 'content': 'abandon', 'translation': '放弃'},
        {'id': 'card-2', 'content': 'ephemeral', 'translation': '短暂的'},
      ],
      sources: [
        {'id': 'source-1', 'imagePath': '/path/to/image.jpg'},
      ],
      reviewLogs: [
        {'id': 'log-1', 'cardId': 'card-1', 'quality': 5},
      ],
      gameSessions: [
        {'id': 'session-1', 'gameType': 'match', 'score': 100},
      ],
      userProfile: {
        'id': 'user-1',
        'totalScore': 1500,
        'level': 4,
      },
    );

    group('toJson', () {
      test('正确序列化所有字段', () {
        final json = testExportData.toJson();

        expect(json['version'], '1.0');
        expect(json['exportTime'], '2024-06-15T10:30:00Z');
        expect(json['appVersion'], '1.0.0');
        expect(json['cards'], isA<List>());
        expect(json['cards'].length, 2);
        expect(json['sources'], isA<List>());
        expect(json['sources'].length, 1);
        expect(json['reviewLogs'], isA<List>());
        expect(json['reviewLogs'].length, 1);
        expect(json['gameSessions'], isA<List>());
        expect(json['gameSessions'].length, 1);
        expect(json['userProfile'], isA<Map>());
      });

      test('userProfile为null时不包含在JSON中', () {
        final data = ExportData(
          version: '1.0',
          exportTime: '2024-06-15T10:30:00Z',
          appVersion: '1.0.0',
          cards: [],
          sources: [],
          reviewLogs: [],
          gameSessions: [],
        );

        final json = data.toJson();

        expect(json['userProfile'], isNull);
      });

      test('空列表正确序列化', () {
        final data = ExportData(
          version: '1.0',
          exportTime: '2024-06-15T10:30:00Z',
          appVersion: '1.0.0',
          cards: [],
          sources: [],
          reviewLogs: [],
          gameSessions: [],
        );

        final json = data.toJson();

        expect(json['cards'], isEmpty);
        expect(json['sources'], isEmpty);
        expect(json['reviewLogs'], isEmpty);
        expect(json['gameSessions'], isEmpty);
      });
    });

    group('fromJson', () {
      test('正确反序列化所有字段', () {
        final json = {
          'version': '1.0',
          'exportTime': '2024-06-15T10:30:00Z',
          'appVersion': '1.0.0',
          'cards': [
            {'id': 'card-1', 'content': 'abandon', 'translation': '放弃'},
          ],
          'sources': [
            {'id': 'source-1', 'imagePath': '/path/to/image.jpg'},
          ],
          'reviewLogs': [
            {'id': 'log-1', 'cardId': 'card-1', 'quality': 5},
          ],
          'gameSessions': [
            {'id': 'session-1', 'gameType': 'match', 'score': 100},
          ],
          'userProfile': {
            'id': 'user-1',
            'totalScore': 1500,
          },
        };

        final data = ExportData.fromJson(json);

        expect(data.version, '1.0');
        expect(data.exportTime, '2024-06-15T10:30:00Z');
        expect(data.appVersion, '1.0.0');
        expect(data.cards.length, 1);
        expect(data.sources.length, 1);
        expect(data.reviewLogs.length, 1);
        expect(data.gameSessions.length, 1);
        expect(data.userProfile, isNotNull);
        expect(data.userProfile!['id'], 'user-1');
      });

      test('userProfile为null时正确处理', () {
        final json = {
          'version': '1.0',
          'exportTime': '2024-06-15T10:30:00Z',
          'appVersion': '1.0.0',
          'cards': [],
          'sources': [],
          'reviewLogs': [],
          'gameSessions': [],
          'userProfile': null,
        };

        final data = ExportData.fromJson(json);

        expect(data.userProfile, isNull);
      });
    });

    group('往返转换一致性', () {
      test('toJson → fromJson 往返一致', () {
        final json = testExportData.toJson();
        final restored = ExportData.fromJson(json);

        expect(restored.version, testExportData.version);
        expect(restored.exportTime, testExportData.exportTime);
        expect(restored.appVersion, testExportData.appVersion);
        expect(restored.cards.length, testExportData.cards.length);
        expect(restored.sources.length, testExportData.sources.length);
        expect(restored.reviewLogs.length, testExportData.reviewLogs.length);
        expect(restored.gameSessions.length, testExportData.gameSessions.length);
        expect(restored.userProfile, isNotNull);
        expect(restored.userProfile!['id'], testExportData.userProfile!['id']);
      });

      test('无userProfile时往返一致', () {
        final data = ExportData(
          version: '1.0',
          exportTime: '2024-06-15T10:30:00Z',
          appVersion: '1.0.0',
          cards: [],
          sources: [],
          reviewLogs: [],
          gameSessions: [],
        );

        final json = data.toJson();
        final restored = ExportData.fromJson(json);

        expect(restored.version, data.version);
        expect(restored.exportTime, data.exportTime);
        expect(restored.appVersion, data.appVersion);
        expect(restored.userProfile, isNull);
      });
    });

    group('缺少可选字段时的容错', () {
      test('userProfile缺失时fromJson正常工作', () {
        final json = {
          'version': '1.0',
          'exportTime': '2024-06-15T10:30:00Z',
          'appVersion': '1.0.0',
          'cards': [],
          'sources': [],
          'reviewLogs': [],
          'gameSessions': [],
        };

        expect(() => ExportData.fromJson(json), returnsNormally);

        final data = ExportData.fromJson(json);
        expect(data.userProfile, isNull);
      });

      test('cards内容正确保留Map结构', () {
        final json = {
          'version': '1.0',
          'exportTime': '2024-06-15T10:30:00Z',
          'appVersion': '1.0.0',
          'cards': [
            {'id': 'card-1', 'content': 'abandon', 'translation': '放弃'},
          ],
          'sources': [],
          'reviewLogs': [],
          'gameSessions': [],
        };

        final data = ExportData.fromJson(json);

        expect(data.cards[0]['id'], 'card-1');
        expect(data.cards[0]['content'], 'abandon');
        expect(data.cards[0]['translation'], '放弃');
      });
    });
  });
}
