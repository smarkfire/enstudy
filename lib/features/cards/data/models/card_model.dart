import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:enstudy/core/database/app_database.dart';
import 'package:enstudy/features/cards/domain/entities/card.dart' as domain;

extension CardRowX on CardRow {
  domain.Card toEntity() => domain.Card(
        id: id,
        type: type,
        content: content,
        translation: translation,
        phonetic: phonetic,
        example: example,
        exampleTranslation: exampleTranslation,
        sourceId: sourceId,
        tags: (jsonDecode(tags) as List).cast<String>(),
        difficulty: difficulty,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
        reviewCount: reviewCount,
        correctCount: correctCount,
        nextReview: DateTime.fromMillisecondsSinceEpoch(nextReview),
        interval: interval,
        easeFactor: easeFactor,
        status: status,
      );
}

extension CardEntityX on domain.Card {
  CardsCompanion toCompanion() => CardsCompanion(
        id: Value(id),
        type: Value(type),
        content: Value(content),
        translation: Value(translation),
        phonetic: Value(phonetic),
        example: Value(example),
        exampleTranslation: Value(exampleTranslation),
        sourceId: Value(sourceId),
        tags: Value(jsonEncode(tags)),
        difficulty: Value(difficulty),
        createdAt: Value(createdAt.millisecondsSinceEpoch),
        reviewCount: Value(reviewCount),
        correctCount: Value(correctCount),
        nextReview: Value(nextReview.millisecondsSinceEpoch),
        interval: Value(interval),
        easeFactor: Value(easeFactor),
        status: Value(status),
      );

  CardRow toRow() => CardRow(
        id: id,
        type: type,
        content: content,
        translation: translation,
        phonetic: phonetic,
        example: example,
        exampleTranslation: exampleTranslation,
        sourceId: sourceId,
        tags: jsonEncode(tags),
        difficulty: difficulty,
        createdAt: createdAt.millisecondsSinceEpoch,
        reviewCount: reviewCount,
        correctCount: correctCount,
        nextReview: nextReview.millisecondsSinceEpoch,
        interval: interval,
        easeFactor: easeFactor,
        status: status,
      );
}
