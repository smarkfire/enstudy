import 'dart:convert';
import 'package:enstudy/core/utils/universal_io.dart';

import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

import 'package:enstudy/core/database/app_database.dart';
import 'package:enstudy/core/database/daos/card_dao.dart';
import 'package:enstudy/core/database/daos/source_dao.dart';
import 'package:enstudy/core/database/daos/game_session_dao.dart';
import 'package:enstudy/core/database/daos/review_log_dao.dart';
import 'package:enstudy/core/database/daos/user_profile_dao.dart';
import 'package:enstudy/features/profile/data/models/export_data.dart';

enum ConflictStrategy { keepNewer, overwrite, skip }

class ImportPreview {
  final int cardCount;
  final int sourceCount;
  final int reviewLogCount;
  final int gameSessionCount;
  final bool hasImages;
  final String version;

  const ImportPreview({
    required this.cardCount,
    required this.sourceCount,
    required this.reviewLogCount,
    required this.gameSessionCount,
    required this.hasImages,
    required this.version,
  });
}

class ImportResult {
  final int imported;
  final int skipped;
  final int conflicted;

  const ImportResult({
    required this.imported,
    required this.skipped,
    required this.conflicted,
  });
}

class DataTransferService {
  final AppDatabase _db;
  final CardDao _cardDao;
  final SourceDao _sourceDao;
  final GameSessionDao _gameSessionDao;
  final ReviewLogDao _reviewLogDao;
  final UserProfileDao _userProfileDao;

  DataTransferService(
    this._db,
    this._cardDao,
    this._sourceDao,
    this._gameSessionDao,
    this._reviewLogDao,
    this._userProfileDao,
  );

  Future<File> exportData({bool includeImages = false}) async {
    final cards = await _cardDao.getAllCards().first;
    final sources = await _sourceDao.getAllSources().first;
    final gameSessions = await _gameSessionDao.getAllSessions().first;
    final reviewLogs = await _reviewLogDao.getAllLogs().first;
    final profileRow = await _userProfileDao.getProfile().first;

    final exportData = ExportData(
      version: '1.0',
      exportTime: DateTime.now().toIso8601String(),
      appVersion: '1.0.0',
      cards: cards.map((c) => _cardRowToMap(c)).toList(),
      sources: sources.map((s) => _sourceRowToMap(s)).toList(),
      reviewLogs: reviewLogs.map((r) => _reviewLogRowToMap(r)).toList(),
      gameSessions: gameSessions.map((g) => _gameSessionRowToMap(g)).toList(),
      userProfile: profileRow != null ? _userProfileRowToMap(profileRow) : null,
    );

    final jsonStr = const JsonEncoder.withIndent('  ').convert(exportData.toJson());
    final dir = await getTemporaryDirectory();
    final now = DateTime.now();
    final fileName = 'enstudy_backup_${DateFormat('yyyyMMdd_HHmmss').format(now)}.json';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(jsonStr);
    return file;
  }

  Future<ImportPreview> previewImport(String filePath) async {
    final file = File(filePath);
    final jsonStr = await file.readAsString();
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    final data = ExportData.fromJson(json);

    return ImportPreview(
      cardCount: data.cards.length,
      sourceCount: data.sources.length,
      reviewLogCount: data.reviewLogs.length,
      gameSessionCount: data.gameSessions.length,
      hasImages: data.sources.any((s) => s.containsKey('imagePath') && s['imagePath'] != null),
      version: data.version,
    );
  }

  Future<ImportResult> importData(
    String filePath, {
    ConflictStrategy strategy = ConflictStrategy.keepNewer,
  }) async {
    final file = File(filePath);
    final jsonStr = await file.readAsString();
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    final data = ExportData.fromJson(json);

    int imported = 0;
    int skipped = 0;
    int conflicted = 0;

    await _db.transaction(() async {
      for (final cardMap in data.cards) {
        final existing = await _cardDao.getCardById(cardMap['id'] as String);
        if (existing != null) {
          switch (strategy) {
            case ConflictStrategy.keepNewer:
              final existingTime = existing.createdAt;
              final importTime = cardMap['createdAt'] as int;
              if (importTime > existingTime) {
                await _cardDao.insertCard(_mapToCardCompanion(cardMap));
                imported++;
              } else {
                skipped++;
              }
              break;
            case ConflictStrategy.overwrite:
              await _cardDao.insertCard(_mapToCardCompanion(cardMap));
              imported++;
              break;
            case ConflictStrategy.skip:
              conflicted++;
              skipped++;
              break;
          }
        } else {
          await _cardDao.insertCard(_mapToCardCompanion(cardMap));
          imported++;
        }
      }

      for (final sourceMap in data.sources) {
        try {
          await _sourceDao.insertSource(_mapToSourceCompanion(sourceMap));
          imported++;
        } catch (_) {
          if (strategy == ConflictStrategy.skip) {
            skipped++;
            conflicted++;
          } else {
            await _sourceDao.insertSource(_mapToSourceCompanion(sourceMap));
            imported++;
          }
        }
      }

      for (final logMap in data.reviewLogs) {
        try {
          await _reviewLogDao.insertLog(_mapToReviewLogCompanion(logMap));
          imported++;
        } catch (_) {
          skipped++;
          conflicted++;
        }
      }

      for (final sessionMap in data.gameSessions) {
        try {
          await _gameSessionDao.insertSession(_mapToGameSessionCompanion(sessionMap));
          imported++;
        } catch (_) {
          skipped++;
          conflicted++;
        }
      }

      if (data.userProfile != null) {
        await _userProfileDao.saveProfile(_mapToUserProfileCompanion(data.userProfile!));
        imported++;
      }
    });

    return ImportResult(imported: imported, skipped: skipped, conflicted: conflicted);
  }

  Map<String, dynamic> _cardRowToMap(CardRow row) => {
        'id': row.id,
        'type': row.type,
        'content': row.content,
        'translation': row.translation,
        'phonetic': row.phonetic,
        'example': row.example,
        'exampleTranslation': row.exampleTranslation,
        'sourceId': row.sourceId,
        'tags': row.tags,
        'difficulty': row.difficulty,
        'createdAt': row.createdAt,
        'reviewCount': row.reviewCount,
        'correctCount': row.correctCount,
        'nextReview': row.nextReview,
        'interval': row.interval,
        'easeFactor': row.easeFactor,
        'status': row.status,
      };

  Map<String, dynamic> _sourceRowToMap(SourceRow row) => {
        'id': row.id,
        'imagePath': row.imagePath,
        'thumbnailPath': row.thumbnailPath,
        'createdAt': row.createdAt,
      };

  Map<String, dynamic> _reviewLogRowToMap(ReviewLogRow row) => {
        'id': row.id,
        'cardId': row.cardId,
        'sessionId': row.sessionId,
        'quality': row.quality,
        'answeredAt': row.answeredAt,
        'gameType': row.gameType,
      };

  Map<String, dynamic> _gameSessionRowToMap(GameSessionRow row) => {
        'id': row.id,
        'gameType': row.gameType,
        'startedAt': row.startedAt,
        'endedAt': row.endedAt,
        'score': row.score,
        'totalQuestions': row.totalQuestions,
        'correctQuestions': row.correctQuestions,
      };

  Map<String, dynamic> _userProfileRowToMap(UserProfileRow row) => {
        'id': row.id,
        'totalScore': row.totalScore,
        'level': row.level,
        'streakDays': row.streakDays,
        'lastCheckin': row.lastCheckin,
        'newCardsPerDay': row.newCardsPerDay,
        'remindTime': row.remindTime,
      };

  Insertable<CardRow> _mapToCardCompanion(Map<String, dynamic> map) => CardsCompanion(
        id: Value(map['id'] as String),
        type: Value(map['type'] as String),
        content: Value(map['content'] as String),
        translation: Value(map['translation'] as String),
        phonetic: Value(map['phonetic'] as String?),
        example: Value(map['example'] as String?),
        exampleTranslation: Value(map['exampleTranslation'] as String?),
        sourceId: Value(map['sourceId'] as String?),
        tags: Value(map['tags'] as String? ?? '[]'),
        difficulty: Value(map['difficulty'] as int? ?? 3),
        createdAt: Value(map['createdAt'] as int),
        reviewCount: Value(map['reviewCount'] as int? ?? 0),
        correctCount: Value(map['correctCount'] as int? ?? 0),
        nextReview: Value(map['nextReview'] as int),
        interval: Value(map['interval'] as double? ?? 1.0),
        easeFactor: Value(map['easeFactor'] as double? ?? 2.5),
        status: Value(map['status'] as String? ?? 'new'),
      );

  Insertable<SourceRow> _mapToSourceCompanion(Map<String, dynamic> map) => SourcesCompanion(
        id: Value(map['id'] as String),
        imagePath: Value(map['imagePath'] as String),
        thumbnailPath: Value(map['thumbnailPath'] as String?),
        createdAt: Value(map['createdAt'] as int),
      );

  Insertable<ReviewLogRow> _mapToReviewLogCompanion(Map<String, dynamic> map) => ReviewLogsCompanion(
        id: Value(map['id'] as String),
        cardId: Value(map['cardId'] as String),
        sessionId: Value(map['sessionId'] as String?),
        quality: Value(map['quality'] as int),
        answeredAt: Value(map['answeredAt'] as int),
        gameType: Value(map['gameType'] as String?),
      );

  Insertable<GameSessionRow> _mapToGameSessionCompanion(Map<String, dynamic> map) => GameSessionsCompanion(
        id: Value(map['id'] as String),
        gameType: Value(map['gameType'] as String),
        startedAt: Value(map['startedAt'] as int),
        endedAt: Value(map['endedAt'] as int?),
        score: Value(map['score'] as int? ?? 0),
        totalQuestions: Value(map['totalQuestions'] as int? ?? 0),
        correctQuestions: Value(map['correctQuestions'] as int? ?? 0),
      );

  Insertable<UserProfileRow> _mapToUserProfileCompanion(Map<String, dynamic> map) => UserProfilesCompanion(
        id: Value(map['id'] as String),
        totalScore: Value(map['totalScore'] as int? ?? 0),
        level: Value(map['level'] as int? ?? 1),
        streakDays: Value(map['streakDays'] as int? ?? 0),
        lastCheckin: Value(map['lastCheckin'] as int?),
        newCardsPerDay: Value(map['newCardsPerDay'] as int? ?? 10),
        remindTime: Value(map['remindTime'] as String? ?? '08:00'),
      );
}
