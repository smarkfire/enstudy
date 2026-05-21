import 'package:freezed_annotation/freezed_annotation.dart';

part 'ocr_result.freezed.dart';
part 'ocr_result.g.dart';

enum MarkType { highlight, underline, circle }

@Freezed()
class OcrWord with _$OcrWord {
  const factory OcrWord({
    required String text,
    required double left,
    required double top,
    required double width,
    required double height,
  }) = _OcrWord;

  factory OcrWord.fromJson(Map<String, dynamic> json) => _$OcrWordFromJson(json);
}

@Freezed()
class MarkedContent with _$MarkedContent {
  const factory MarkedContent({
    required String text,
    required MarkType markType,
    @Default(0) int color,
  }) = _MarkedContent;

  factory MarkedContent.fromJson(Map<String, dynamic> json) =>
      _$MarkedContentFromJson(json);
}

@Freezed()
class OcrResult with _$OcrResult {
  const factory OcrResult({
    required String text,
    @Default([]) List<OcrWord> words,
    @Default([]) List<MarkedContent> markedContents,
  }) = _OcrResult;

  factory OcrResult.fromJson(Map<String, dynamic> json) =>
      _$OcrResultFromJson(json);
}

@Freezed()
class MarkRegion with _$MarkRegion {
  const factory MarkRegion({
    required double left,
    required double top,
    required double width,
    required double height,
    required int markColor,
    required MarkType markType,
  }) = _MarkRegion;

  factory MarkRegion.fromJson(Map<String, dynamic> json) =>
      _$MarkRegionFromJson(json);
}

@Freezed()
class MatchResult with _$MatchResult {
  const factory MatchResult({
    @Default([]) List<MarkedContent> markedContents,
    @Default('') String unmarkedText,
  }) = _MatchResult;

  factory MatchResult.fromJson(Map<String, dynamic> json) =>
      _$MatchResultFromJson(json);
}

@Freezed()
class MarkedAnalysisItem with _$MarkedAnalysisItem {
  const factory MarkedAnalysisItem({
    required String content,
    required String translation,
    @Default('') String phonetic,
    @Default('') String example,
    @Default('') String exampleTranslation,
  }) = _MarkedAnalysisItem;

  factory MarkedAnalysisItem.fromJson(Map<String, dynamic> json) =>
      _$MarkedAnalysisItemFromJson(json);
}

@Freezed()
class RecommendationItem with _$RecommendationItem {
  const factory RecommendationItem({
    required String content,
    required String translation,
    @Default('') String phonetic,
    @Default('') String example,
    @Default('') String exampleTranslation,
    @Default('word') String type,
    @Default('') String reason,
  }) = _RecommendationItem;

  factory RecommendationItem.fromJson(Map<String, dynamic> json) =>
      _$RecommendationItemFromJson(json);
}

@Freezed()
class AiAnalysisResult with _$AiAnalysisResult {
  const factory AiAnalysisResult({
    @Default([]) List<MarkedAnalysisItem> markedAnalysis,
    @Default([]) List<RecommendationItem> recommendations,
  }) = _AiAnalysisResult;

  factory AiAnalysisResult.fromJson(Map<String, dynamic> json) =>
      _$AiAnalysisResultFromJson(json);
}
