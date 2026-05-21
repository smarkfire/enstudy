import 'package:mocktail/mocktail.dart';
import 'package:enstudy/features/cards/domain/entities/card.dart';
import 'package:enstudy/features/profile/domain/entities/user_profile.dart';
import 'package:enstudy/features/upload/domain/entities/ocr_result.dart';
import 'package:enstudy/features/cards/domain/repositories/card_repository.dart';
import 'package:enstudy/features/profile/domain/repositories/profile_repository.dart';
import 'package:enstudy/features/games/domain/repositories/game_repository.dart';
import 'package:enstudy/features/games/domain/entities/game_type.dart';

Card createTestCard({
  String id = 'test-card-1',
  String type = 'word',
  String content = 'abandon',
  String translation = '放弃；抛弃',
  String? phonetic = '/əˈbændən/',
  String? example = 'He abandoned his car in the snow.',
  String? exampleTranslation = '他把车丢弃在雪地里。',
  String? sourceId,
  List<String> tags = const ['CET4', 'CET6'],
  int difficulty = 3,
  DateTime? createdAt,
  int reviewCount = 0,
  int correctCount = 0,
  DateTime? nextReview,
  double interval = 1.0,
  double easeFactor = 2.5,
  String status = 'new',
}) {
  return Card(
    id: id,
    type: type,
    content: content,
    translation: translation,
    phonetic: phonetic,
    example: example,
    exampleTranslation: exampleTranslation,
    sourceId: sourceId,
    tags: tags,
    difficulty: difficulty,
    createdAt: createdAt ?? DateTime(2024, 1, 1),
    reviewCount: reviewCount,
    correctCount: correctCount,
    nextReview: nextReview ?? DateTime(2024, 1, 2),
    interval: interval,
    easeFactor: easeFactor,
    status: status,
  );
}

UserProfile createTestUserProfile({
  String id = 'test-user-1',
  int totalScore = 0,
  int level = 1,
  int streakDays = 0,
  DateTime? lastCheckin,
  int newCardsPerDay = 10,
  String remindTime = '08:00',
}) {
  return UserProfile(
    id: id,
    totalScore: totalScore,
    level: level,
    streakDays: streakDays,
    lastCheckin: lastCheckin,
    newCardsPerDay: newCardsPerDay,
    remindTime: remindTime,
  );
}

OcrResult createTestOcrResult({
  String text = 'The quick brown fox jumps over the lazy dog',
  List<OcrWord>? words,
  List<MarkedContent>? markedContents,
}) {
  return OcrResult(
    text: text,
    words: words ??
        [
          const OcrWord(text: 'The', left: 0, top: 0, width: 30, height: 20),
          const OcrWord(
              text: 'quick', left: 35, top: 0, width: 40, height: 20),
          const OcrWord(
              text: 'brown', left: 80, top: 0, width: 45, height: 20),
          const OcrWord(text: 'fox', left: 130, top: 0, width: 30, height: 20),
        ],
    markedContents: markedContents ?? [],
  );
}

class MockCardRepository extends Mock implements CardRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockGameRepository extends Mock implements GameRepository {}

void registerTestFallbackValues() {
  registerFallbackValue(createTestCard());
  registerFallbackValue(createTestUserProfile());
  registerFallbackValue(GameType.match);
}
