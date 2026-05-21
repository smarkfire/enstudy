import 'package:freezed_annotation/freezed_annotation.dart';

part 'card.freezed.dart';
part 'card.g.dart';

@Freezed()
class Card with _$Card {
  const factory Card({
    required String id,
    required String type,
    required String content,
    required String translation,
    String? phonetic,
    String? example,
    String? exampleTranslation,
    String? sourceId,
    @Default([]) List<String> tags,
    @Default(3) int difficulty,
    required DateTime createdAt,
    @Default(0) int reviewCount,
    @Default(0) int correctCount,
    required DateTime nextReview,
    @Default(1.0) double interval,
    @Default(2.5) double easeFactor,
    @Default('new') String status,
  }) = _Card;

  const Card._();

  factory Card.fromJson(Map<String, dynamic> json) => _$CardFromJson(json);
}
