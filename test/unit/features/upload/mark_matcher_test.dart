import 'package:flutter_test/flutter_test.dart';
import 'package:enstudy/features/upload/data/datasources/mark_matcher.dart';
import 'package:enstudy/features/upload/domain/entities/ocr_result.dart';

void main() {
  late MarkMatcher markMatcher;

  setUp(() {
    markMatcher = MarkMatcher();
  });

  group('标记匹配', () {
    group('IoU计算', () {
      test('完全重叠时IoU为1.0', () {
        const ocrResult = OcrResult(
          text: 'abandon',
          words: [
            const OcrWord(
                text: 'abandon', left: 0, top: 0, width: 100, height: 50),
          ],
        );
        final markRegions = [
          const MarkRegion(
            left: 0,
            top: 0,
            width: 100,
            height: 50,
            markColor: 0xFFFF00,
            markType: MarkType.highlight,
          ),
        ];

        final result = markMatcher.match(ocrResult, markRegions);

        expect(result.markedContents.length, 1);
        expect(result.markedContents.first.text, 'abandon');
      });

      test('无重叠时IoU为0.0', () {
        const ocrResult = OcrResult(
          text: 'abandon',
          words: [
            const OcrWord(
                text: 'abandon', left: 0, top: 0, width: 100, height: 50),
          ],
        );
        final markRegions = [
          const MarkRegion(
            left: 200,
            top: 200,
            width: 100,
            height: 50,
            markColor: 0xFFFF00,
            markType: MarkType.highlight,
          ),
        ];

        final result = markMatcher.match(ocrResult, markRegions);

        expect(result.markedContents.length, 0);
        expect(result.unmarkedText, 'abandon');
      });

      test('部分重叠且IoU大于阈值时匹配成功', () {
        const ocrResult = OcrResult(
          text: 'abandon',
          words: [
            const OcrWord(
                text: 'abandon', left: 0, top: 0, width: 100, height: 100),
          ],
        );
        final markRegions = [
          const MarkRegion(
            left: 50,
            top: 0,
            width: 100,
            height: 100,
            markColor: 0xFFFF00,
            markType: MarkType.highlight,
          ),
        ];

        final result = markMatcher.match(ocrResult, markRegions);

        expect(result.markedContents.length, 1);
        expect(result.markedContents.first.text, 'abandon');
      });

      test('部分重叠且IoU小于阈值时不匹配', () {
        const ocrResult = OcrResult(
          text: 'abandon',
          words: [
            const OcrWord(
                text: 'abandon', left: 0, top: 0, width: 100, height: 100),
          ],
        );
        final markRegions = [
          const MarkRegion(
            left: 80,
            top: 0,
            width: 100,
            height: 100,
            markColor: 0xFFFF00,
            markType: MarkType.highlight,
          ),
        ];

        final result = markMatcher.match(ocrResult, markRegions);

        expect(result.markedContents.length, 0);
        expect(result.unmarkedText, 'abandon');
      });
    });

    group('标记颜色分类', () {
      test('黄色标记分类为highlight', () {
        const yellowColor = (255 << 16) | (255 << 8) | 0;
        const ocrResult = OcrResult(
          text: 'abandon',
          words: [
            const OcrWord(
                text: 'abandon', left: 0, top: 0, width: 100, height: 50),
          ],
        );
        final markRegions = [
          MarkRegion(
            left: 0,
            top: 0,
            width: 100,
            height: 50,
            markColor: yellowColor,
            markType: MarkType.underline,
          ),
        ];

        final result = markMatcher.match(ocrResult, markRegions);

        expect(result.markedContents.first.markType, MarkType.highlight);
      });

      test('绿色标记分类为circle', () {
        const greenColor = (0 << 16) | (200 << 8) | 0;
        const ocrResult = OcrResult(
          text: 'ephemeral',
          words: [
            const OcrWord(
                text: 'ephemeral', left: 0, top: 0, width: 100, height: 50),
          ],
        );
        final markRegions = [
          MarkRegion(
            left: 0,
            top: 0,
            width: 100,
            height: 50,
            markColor: greenColor,
            markType: MarkType.highlight,
          ),
        ];

        final result = markMatcher.match(ocrResult, markRegions);

        expect(result.markedContents.first.markType, MarkType.circle);
      });

      test('粉色标记分类为underline', () {
        const pinkColor = (255 << 16) | (0 << 8) | 200;
        const ocrResult = OcrResult(
          text: 'resilient',
          words: [
            const OcrWord(
                text: 'resilient', left: 0, top: 0, width: 100, height: 50),
          ],
        );
        final markRegions = [
          MarkRegion(
            left: 0,
            top: 0,
            width: 100,
            height: 50,
            markColor: pinkColor,
            markType: MarkType.highlight,
          ),
        ];

        final result = markMatcher.match(ocrResult, markRegions);

        expect(result.markedContents.first.markType, MarkType.underline);
      });

      test('不匹配任何颜色条件时使用检测到的类型', () {
        const unknownColor = (100 << 16) | (100 << 8) | 100;
        const ocrResult = OcrResult(
          text: 'pragmatic',
          words: [
            const OcrWord(
                text: 'pragmatic', left: 0, top: 0, width: 100, height: 50),
          ],
        );
        final markRegions = [
          MarkRegion(
            left: 0,
            top: 0,
            width: 100,
            height: 50,
            markColor: unknownColor,
            markType: MarkType.circle,
          ),
        ];

        final result = markMatcher.match(ocrResult, markRegions);

        expect(result.markedContents.first.markType, MarkType.circle);
      });
    });

    group('低于阈值的匹配被忽略', () {
      test('IoU等于0.3时不匹配', () {
        const ocrResult = OcrResult(
          text: 'ubiquitous',
          words: [
            const OcrWord(
              text: 'ubiquitous',
              left: 0,
              top: 0,
              width: 100,
              height: 100,
            ),
          ],
        );
        final markRegions = [
          const MarkRegion(
            left: 0,
            top: 0,
            width: 30,
            height: 100,
            markColor: 0xFFFF00,
            markType: MarkType.highlight,
          ),
        ];

        final result = markMatcher.match(ocrResult, markRegions);

        expect(result.markedContents.length, 0);
        expect(result.unmarkedText, 'ubiquitous');
      });

      test('IoU略大于0.3时匹配', () {
        const ocrResult = OcrResult(
          text: 'ubiquitous',
          words: [
            const OcrWord(
              text: 'ubiquitous',
              left: 0,
              top: 0,
              width: 100,
              height: 100,
            ),
          ],
        );
        final markRegions = [
          const MarkRegion(
            left: 0,
            top: 0,
            width: 35,
            height: 100,
            markColor: 0xFFFF00,
            markType: MarkType.highlight,
          ),
        ];

        final result = markMatcher.match(ocrResult, markRegions);

        expect(result.markedContents.length, 1);
      });

      test('多个标记区域时只匹配IoU超过阈值的', () {
        const ocrResult = OcrResult(
          text: 'quick brown',
          words: [
            const OcrWord(
                text: 'quick', left: 0, top: 0, width: 50, height: 20),
            const OcrWord(
                text: 'brown', left: 55, top: 0, width: 50, height: 20),
          ],
        );
        final markRegions = [
          const MarkRegion(
            left: 0,
            top: 0,
            width: 50,
            height: 20,
            markColor: 0xFFFF00,
            markType: MarkType.highlight,
          ),
          const MarkRegion(
            left: 200,
            top: 200,
            width: 50,
            height: 20,
            markColor: 0x00C800,
            markType: MarkType.circle,
          ),
        ];

        final result = markMatcher.match(ocrResult, markRegions);

        expect(result.markedContents.length, 1);
        expect(result.markedContents.first.text, 'quick');
        expect(result.unmarkedText, 'brown');
      });
    });

    group('无标记区域', () {
      test('没有标记区域时所有单词都为未标记', () {
        const ocrResult = OcrResult(
          text: 'hello world',
          words: [
            const OcrWord(
                text: 'hello', left: 0, top: 0, width: 50, height: 20),
            const OcrWord(
                text: 'world', left: 55, top: 0, width: 50, height: 20),
          ],
        );

        final result = markMatcher.match(ocrResult, []);

        expect(result.markedContents.length, 0);
        expect(result.unmarkedText, 'hello world');
      });
    });
  });
}
