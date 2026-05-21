import 'package:drift/drift.dart';
import 'package:enstudy/core/database/app_database.dart';
import 'package:enstudy/core/database/daos/source_dao.dart';
import 'package:enstudy/features/upload/domain/entities/ocr_result.dart';
import 'package:enstudy/features/upload/domain/repositories/upload_repository.dart';

class UploadRepositoryImpl implements UploadRepository {
  final SourceDao _sourceDao;

  UploadRepositoryImpl(this._sourceDao);

  @override
  Future<OcrResult> processImage(String imagePath) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveSource({
    required String id,
    required String imagePath,
    String? thumbnailPath,
  }) =>
      _sourceDao.insertSource(SourcesCompanion(
        id: Value(id),
        imagePath: Value(imagePath),
        thumbnailPath: Value(thumbnailPath),
        createdAt: Value(DateTime.now().millisecondsSinceEpoch),
      ));

  @override
  Future<void> deleteSource(String id) => _sourceDao.deleteSource(id);

  @override
  Stream<List<Map<String, dynamic>>> getSources() => _sourceDao
      .getAllSources()
      .map((rows) => rows.map((r) => r.toJson()).toList());

  @override
  Future<Map<String, dynamic>?> getSourceById(String id) async {
    final row = await _sourceDao.getSourceById(id);
    return row?.toJson();
  }

  @override
  Stream<List<Map<String, dynamic>>> getRecentSources({int limit = 10}) =>
      _sourceDao
          .getRecentSources(limit: limit)
          .map((rows) => rows.map((r) => r.toJson()).toList());
}
