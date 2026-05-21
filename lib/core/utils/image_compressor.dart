import 'package:enstudy/core/utils/universal_io.dart';
import 'dart:typed_data';

import 'package:image/image.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageCompressor {
  static Future<File> compressToFile({
    required String sourcePath,
    int maxWidth = 1920,
    int maxHeight = 1080,
    int quality = 80,
    String? targetPath,
  }) async {
    final sourceFile = File(sourcePath);
    final bytes = Uint8List.fromList(await sourceFile.readAsBytes());
    final image = decodeImage(bytes)!;

    int width = image.width;
    int height = image.height;

    if (width > maxWidth || height > maxHeight) {
      final ratio = (width / maxWidth < height / maxHeight)
          ? width / maxWidth
          : height / maxHeight;
      width = (width / ratio).round();
      height = (height / ratio).round();
      final resized = copyResize(image, width: width, height: height);
      final encoded = encodeJpg(resized, quality: quality);

      final outputPath = targetPath ?? await _generateOutputPath(sourcePath);
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(encoded);
      return outputFile;
    }

    final encoded = encodeJpg(image, quality: quality);
    final outputPath = targetPath ?? await _generateOutputPath(sourcePath);
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(encoded);
    return outputFile;
  }

  static Future<Uint8List> compressToBytes({
    required String sourcePath,
    int maxWidth = 1920,
    int maxHeight = 1080,
    int quality = 80,
  }) async {
    final sourceFile = File(sourcePath);
    final bytes = Uint8List.fromList(await sourceFile.readAsBytes());
    final image = decodeImage(bytes)!;

    int width = image.width;
    int height = image.height;

    if (width > maxWidth || height > maxHeight) {
      final ratio = (width / maxWidth < height / maxHeight)
          ? width / maxWidth
          : height / maxHeight;
      width = (width / ratio).round();
      height = (height / ratio).round();
      final resized = copyResize(image, width: width, height: height);
      return Uint8List.fromList(encodeJpg(resized, quality: quality));
    }

    return Uint8List.fromList(encodeJpg(image, quality: quality));
  }

  static Future<String> _generateOutputPath(String sourcePath) async {
    final dir = await getTemporaryDirectory();
    final basename = p.basenameWithoutExtension(sourcePath);
    final extension = p.extension(sourcePath);
    return p.join(dir.path, '${basename}_compressed$extension');
  }
}
