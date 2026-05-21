import 'package:enstudy/features/upload/domain/entities/ocr_result.dart';

class UploadResult {
  final String sourceId;
  final OcrResult ocrResult;
  final MatchResult matchResult;
  final AiAnalysisResult aiAnalysisResult;

  const UploadResult({
    required this.sourceId,
    required this.ocrResult,
    required this.matchResult,
    required this.aiAnalysisResult,
  });

  UploadResult copyWith({
    String? sourceId,
    OcrResult? ocrResult,
    MatchResult? matchResult,
    AiAnalysisResult? aiAnalysisResult,
  }) =>
      UploadResult(
        sourceId: sourceId ?? this.sourceId,
        ocrResult: ocrResult ?? this.ocrResult,
        matchResult: matchResult ?? this.matchResult,
        aiAnalysisResult: aiAnalysisResult ?? this.aiAnalysisResult,
      );

  UploadResultEntity toEntity() => UploadResultEntity(
        sourceId: sourceId,
        ocrResult: ocrResult,
        matchResult: matchResult,
        aiAnalysisResult: aiAnalysisResult,
      );

  factory UploadResult.fromEntity(UploadResultEntity entity) => UploadResult(
        sourceId: entity.sourceId,
        ocrResult: entity.ocrResult,
        matchResult: entity.matchResult,
        aiAnalysisResult: entity.aiAnalysisResult,
      );
}

class UploadResultEntity {
  final String sourceId;
  final OcrResult ocrResult;
  final MatchResult matchResult;
  final AiAnalysisResult aiAnalysisResult;

  const UploadResultEntity({
    required this.sourceId,
    required this.ocrResult,
    required this.matchResult,
    required this.aiAnalysisResult,
  });
}
