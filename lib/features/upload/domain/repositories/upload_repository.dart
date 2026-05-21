import 'package:enstudy/features/upload/domain/entities/ocr_result.dart';

abstract class UploadRepository {
  Future<OcrResult> processImage(String imagePath);

  Future<void> saveSource({
    required String id,
    required String imagePath,
    String? thumbnailPath,
  });

  Future<void> deleteSource(String id);

  Stream<List<Map<String, dynamic>>> getSources();

  Future<Map<String, dynamic>?> getSourceById(String id);

  Stream<List<Map<String, dynamic>>> getRecentSources({int limit = 10});
}
