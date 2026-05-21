import 'package:enstudy/features/upload/domain/entities/ocr_result.dart';

class MarkMatcher {
  static const double _iouThreshold = 0.3;

  MatchResult match(OcrResult ocrResult, List<MarkRegion> markRegions) {
    final markedContents = <MarkedContent>[];
    final markedWordIndices = <int>{};
    final unmarkedWords = <String>[];

    for (int i = 0; i < ocrResult.words.length; i++) {
      final word = ocrResult.words[i];
      final wordRect = _Rect.fromOcrWord(word);
      bool isMarked = false;
      MarkType? markType;
      int markColor = 0;

      for (final region in markRegions) {
        final regionRect = _Rect.fromMarkRegion(region);
        final iou = _calculateIoU(wordRect, regionRect);

        if (iou > _iouThreshold) {
          isMarked = true;
          markType = region.markType;
          markColor = region.markColor;
          break;
        }
      }

      if (isMarked && markType != null) {
        markedContents.add(MarkedContent(
          text: word.text,
          markType: _classifyMarkType(markType, markColor),
          color: markColor,
        ));
        markedWordIndices.add(i);
      }
    }

    for (int i = 0; i < ocrResult.words.length; i++) {
      if (!markedWordIndices.contains(i)) {
        unmarkedWords.add(ocrResult.words[i].text);
      }
    }

    return MatchResult(
      markedContents: markedContents,
      unmarkedText: unmarkedWords.join(' '),
    );
  }

  MarkType _classifyMarkType(MarkType detectedType, int color) {
    final r = (color >> 16) & 0xFF;
    final g = (color >> 8) & 0xFF;
    final b = color & 0xFF;

    if (r > 200 && g > 200 && b < 100) {
      return MarkType.highlight;
    } else if (g > 150 && r < 150 && b < 150) {
      return MarkType.circle;
    } else if (r > 150 && b > 100 && g < 120) {
      return MarkType.underline;
    }

    return detectedType;
  }

  double _calculateIoU(_Rect a, _Rect b) {
    final intersectLeft = a.left > b.left ? a.left : b.left;
    final intersectTop = a.top > b.top ? a.top : b.top;
    final intersectRight = a.right < b.right ? a.right : b.right;
    final intersectBottom = a.bottom < b.bottom ? a.bottom : b.bottom;

    if (intersectRight <= intersectLeft || intersectBottom <= intersectTop) {
      return 0.0;
    }

    final intersection = (intersectRight - intersectLeft) *
        (intersectBottom - intersectTop);
    final union = a.area + b.area - intersection;

    if (union <= 0) return 0.0;
    return intersection / union;
  }
}

class _Rect {
  final double left;
  final double top;
  final double right;
  final double bottom;

  _Rect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  double get area => (right - left) * (bottom - top);

  factory _Rect.fromOcrWord(OcrWord word) => _Rect(
        left: word.left,
        top: word.top,
        right: word.left + word.width,
        bottom: word.top + word.height,
      );

  factory _Rect.fromMarkRegion(MarkRegion region) => _Rect(
        left: region.left,
        top: region.top,
        right: region.left + region.width,
        bottom: region.top + region.height,
      );
}
