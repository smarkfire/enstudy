import 'dart:typed_data';

import 'package:image/image.dart';
import 'package:enstudy/features/upload/domain/entities/ocr_result.dart';

class MarkDetectorService {
  static const int _yellowThreshold = 180;
  static const int _pinkThreshold = 150;
  static const int _greenThreshold = 150;
  static const int _minRegionSize = 20;
  static const int _mergeDistance = 10;

  Future<List<MarkRegion>> detectMarks(List<int> imageBytes) async {
    final image = decodeImage(Uint8List.fromList(imageBytes));
    if (image == null) return [];

    final mask = _createHighlightMask(image);
    final regions = _findRegions(mask, image.width, image.height);
    final merged = _mergeCloseRegions(regions);

    return merged.where((r) => r.width >= _minRegionSize || r.height >= _minRegionSize).toList();
  }

  List<List<int>> _createHighlightMask(Image image) {
    final mask = List.generate(
      image.height,
      (_) => List.filled(image.width, 0),
    );

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        if (_isYellow(r, g, b)) {
          mask[y][x] = 1;
        } else if (_isPink(r, g, b)) {
          mask[y][x] = 2;
        } else if (_isGreen(r, g, b)) {
          mask[y][x] = 3;
        }
      }
    }

    return mask;
  }

  bool _isYellow(int r, int g, int b) {
    return r > _yellowThreshold &&
        g > _yellowThreshold &&
        b < 100 &&
        (r - b) > 100 &&
        (g - b) > 80;
  }

  bool _isPink(int r, int g, int b) {
    return r > _pinkThreshold &&
        g < 120 &&
        b > 120 &&
        (r - g) > 80;
  }

  bool _isGreen(int r, int g, int b) {
    return g > _greenThreshold &&
        r < 150 &&
        b < 150 &&
        (g - r) > 40 &&
        (g - b) > 40;
  }

  List<MarkRegion> _findRegions(List<List<int>> mask, int width, int height) {
    final visited = List.generate(
      height,
      (_) => List.filled(width, false),
    );
    final regions = <MarkRegion>[];

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (!visited[y][x] && mask[y][x] > 0) {
          final markType = mask[y][x];
          final bounds = _floodFill(mask, visited, x, y, markType, width, height);
          if (bounds != null) {
            final color = _getColorForType(markType);
            final type = _getMarkTypeForColor(markType);
            regions.add(MarkRegion(
              left: bounds[0].toDouble(),
              top: bounds[1].toDouble(),
              width: (bounds[2] - bounds[0]).toDouble(),
              height: (bounds[3] - bounds[1]).toDouble(),
              markColor: color,
              markType: type,
            ));
          }
        }
      }
    }

    return regions;
  }

  List<int>? _floodFill(
    List<List<int>> mask,
    List<List<bool>> visited,
    int startX,
    int startY,
    int targetMarkType,
    int width,
    int height,
  ) {
    int minX = startX, maxX = startX;
    int minY = startY, maxY = startY;

    final queue = <List<int>>[[startX, startY]];
    visited[startY][startX] = true;

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final cx = current[0];
      final cy = current[1];

      if (cx < minX) minX = cx;
      if (cx > maxX) maxX = cx;
      if (cy < minY) minY = cy;
      if (cy > maxY) maxY = cy;

      final neighbors = [
        [cx + 1, cy],
        [cx - 1, cy],
        [cx, cy + 1],
        [cx, cy - 1],
      ];

      for (final neighbor in neighbors) {
        final nx = neighbor[0];
        final ny = neighbor[1];
        if (nx >= 0 && nx < width && ny >= 0 && ny < height &&
            !visited[ny][nx] && mask[ny][nx] == targetMarkType) {
          visited[ny][nx] = true;
          queue.add([nx, ny]);
        }
      }
    }

    return [minX, minY, maxX, maxY];
  }

  List<MarkRegion> _mergeCloseRegions(List<MarkRegion> regions) {
    if (regions.isEmpty) return regions;

    final merged = <MarkRegion>[regions.first];

    for (int i = 1; i < regions.length; i++) {
      final current = regions[i];
      bool wasMerged = false;

      for (int j = 0; j < merged.length; j++) {
        final existing = merged[j];
        if (existing.markType == current.markType && _isClose(existing, current)) {
          merged[j] = _mergeTwo(existing, current);
          wasMerged = true;
          break;
        }
      }

      if (!wasMerged) {
        merged.add(current);
      }
    }

    return merged;
  }

  bool _isClose(MarkRegion a, MarkRegion b) {
    final aLeft = a.left;
    final aRight = a.left + a.width;
    final aTop = a.top;
    final aBottom = a.top + a.height;

    final bLeft = b.left;
    final bRight = b.left + b.width;
    final bTop = b.top;
    final bBottom = b.top + b.height;

    final horizontalClose = aRight + _mergeDistance >= bLeft && bRight + _mergeDistance >= aLeft;
    final verticalClose = aBottom + _mergeDistance >= bTop && bBottom + _mergeDistance >= aTop;

    return horizontalClose && verticalClose;
  }

  MarkRegion _mergeTwo(MarkRegion a, MarkRegion b) {
    final left = a.left < b.left ? a.left : b.left;
    final top = a.top < b.top ? a.top : b.top;
    final aRight = a.left + a.width;
    final aBottom = a.top + a.height;
    final bRight = b.left + b.width;
    final bBottom = b.top + b.height;
    final right = aRight > bRight ? aRight : bRight;
    final bottom = aBottom > bBottom ? aBottom : bBottom;

    return MarkRegion(
      left: left,
      top: top,
      width: right - left,
      height: bottom - top,
      markColor: a.markColor,
      markType: a.markType,
    );
  }

  int _getColorForType(int markType) {
    switch (markType) {
      case 1:
        return 0xFFFFFF00;
      case 2:
        return 0xFFFF69B4;
      case 3:
        return 0xFF90EE90;
      default:
        return 0xFFFFFF00;
    }
  }

  MarkType _getMarkTypeForColor(int markType) {
    switch (markType) {
      case 1:
        return MarkType.highlight;
      case 2:
        return MarkType.underline;
      case 3:
        return MarkType.circle;
      default:
        return MarkType.highlight;
    }
  }
}
