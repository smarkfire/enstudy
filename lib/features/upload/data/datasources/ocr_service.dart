import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:enstudy/features/upload/domain/entities/ocr_result.dart';

class BaiduOcrService {
  final Dio _dio;

  BaiduOcrService(this._dio);

  static const String _tokenUrl =
      'https://aip.baidubce.com/oauth/2.0/token';
  static const String _ocrUrl =
      'https://aip.baidubce.com/rest/2.0/ocr/v1/general_basic';

  Future<String> getAccessToken(String apiKey, String secretKey) async {
    final response = await _dio.post(
      _tokenUrl,
      queryParameters: {
        'grant_type': 'client_credentials',
        'client_id': apiKey,
        'client_secret': secretKey,
      },
    );
    return response.data['access_token'] as String;
  }

  Future<OcrResult> recognizeText(
    List<int> imageBytes,
    String accessToken,
  ) async {
    final base64Image = base64Encode(imageBytes);
    final response = await _dio.post(
      _ocrUrl,
      queryParameters: {'access_token': accessToken},
      data: 'image=${Uri.encodeComponent(base64Image)}',
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );

    final data = response.data;
    final wordsResult = data['words_result'] as List<dynamic>? ?? [];
    final words = <OcrWord>[];
    final textBuffer = StringBuffer();

    for (final item in wordsResult) {
      final wordsStr = item['words'] as String? ?? '';
      final location = item['location'] as Map<String, dynamic>?;

      if (location != null) {
        words.add(OcrWord(
          text: wordsStr,
          left: (location['left'] as num?)?.toDouble() ?? 0,
          top: (location['top'] as num?)?.toDouble() ?? 0,
          width: (location['width'] as num?)?.toDouble() ?? 0,
          height: (location['height'] as num?)?.toDouble() ?? 0,
        ));
      } else {
        words.add(OcrWord(
          text: wordsStr,
          left: 0,
          top: 0,
          width: 0,
          height: 0,
        ));
      }

      if (textBuffer.isNotEmpty) textBuffer.write('\n');
      textBuffer.write(wordsStr);
    }

    return OcrResult(
      text: textBuffer.toString(),
      words: words,
    );
  }
}
