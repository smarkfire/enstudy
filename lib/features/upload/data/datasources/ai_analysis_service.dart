import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:enstudy/features/upload/domain/entities/ocr_result.dart';

class DeepSeekAiService {
  final Dio _dio;

  DeepSeekAiService(this._dio);

  static const String _baseUrl =
      'https://api.deepseek.com/v1/chat/completions';

  Future<AiAnalysisResult> analyze({
    required String ocrText,
    required List<String> markedContents,
    required List<MarkType> markTypes,
    required String apiKey,
    String? customPrompt,
  }) async {
    final prompt = customPrompt != null && customPrompt.isNotEmpty
        ? _buildCustomPrompt(ocrText, customPrompt)
        : _buildDefaultPrompt(ocrText, markedContents, markTypes);

    final response = await _dio.post(
      _baseUrl,
      options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      ),
      data: {
        'model': 'deepseek-chat',
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.3,
      },
    );

    final choices = response.data['choices'] as List<dynamic>;
    if (choices.isEmpty) {
      return const AiAnalysisResult();
    }

    final content = choices[0]['message']['content'] as String;
    return _parseAiResponse(content);
  }

  String _buildDefaultPrompt(
    String ocrText,
    List<String> markedContents,
    List<MarkType> markTypes,
  ) {
    final markedText = markedContents.asMap().entries.map((entry) {
      final typeStr = _markTypeToString(
        entry.key < markTypes.length ? markTypes[entry.key] : MarkType.highlight,
      );
      return '${entry.value}($typeStr)';
    }).join('、');

    return '''你是一个英语学习助手。请分析以下来自学生学习材料的文本。

OCR识别文本：
$ocrText

学生标记的内容（这些是他们不认识的）：
$markedText

请提供：
1. 对每个标记项：中文翻译、音标（单词类型）、例句
2. 从文本中推荐最多3个学生可能不认识的重要单词/短语

请以JSON格式返回：
{
  "marked_analysis": [
    {
      "content": "word",
      "translation": "翻译",
      "phonetic": "/音标/",
      "example": "Example sentence.",
      "example_translation": "例句翻译"
    }
  ],
  "recommendations": [
    {
      "content": "word",
      "type": "word|phrase|grammar",
      "translation": "翻译",
      "phonetic": "/音标/",
      "example": "Example sentence.",
      "example_translation": "例句翻译",
      "reason": "为什么推荐"
    }
  ]
}''';
  }

  String _buildCustomPrompt(String ocrText, String userPrompt) {
    return '''你是一个英语学习助手。以下是来自学生学习材料的OCR识别文本。

OCR识别文本：
$ocrText

用户的自定义要求：
$userPrompt

请根据用户的要求分析文本，提取英语学习卡片。每张卡片包含：内容、翻译、音标、例句、例句翻译。

请以JSON格式返回：
{
  "marked_analysis": [
    {
      "content": "word/phrase",
      "translation": "翻译",
      "phonetic": "/音标/",
      "example": "Example sentence.",
      "example_translation": "例句翻译"
    }
  ],
  "recommendations": [
    {
      "content": "word/phrase",
      "type": "word|phrase|grammar",
      "translation": "翻译",
      "phonetic": "/音标/",
      "example": "Example sentence.",
      "example_translation": "例句翻译",
      "reason": "为什么推荐"
    }
  ]
}

注意：
- marked_analysis 放用户要求中明确提到的内容
- recommendations 放你额外推荐的内容
- 严格返回JSON，不要添加其他文字''';
  }

  AiAnalysisResult _parseAiResponse(String content) {
    try {
      final jsonStr = _extractJson(content);
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;

      final markedAnalysis = <MarkedAnalysisItem>[];
      final markedList = json['marked_analysis'] as List<dynamic>? ?? [];
      for (final item in markedList) {
        markedAnalysis.add(MarkedAnalysisItem(
          content: item['content'] as String? ?? '',
          translation: item['translation'] as String? ?? '',
          phonetic: item['phonetic'] as String? ?? '',
          example: item['example'] as String? ?? '',
          exampleTranslation: item['example_translation'] as String? ?? '',
        ));
      }

      final recommendations = <RecommendationItem>[];
      final recList = json['recommendations'] as List<dynamic>? ?? [];
      for (final item in recList) {
        recommendations.add(RecommendationItem(
          content: item['content'] as String? ?? '',
          translation: item['translation'] as String? ?? '',
          phonetic: item['phonetic'] as String? ?? '',
          example: item['example'] as String? ?? '',
          exampleTranslation: item['example_translation'] as String? ?? '',
          type: item['type'] as String? ?? 'word',
          reason: item['reason'] as String? ?? '',
        ));
      }

      return AiAnalysisResult(
        markedAnalysis: markedAnalysis,
        recommendations: recommendations,
      );
    } catch (_) {
      return const AiAnalysisResult();
    }
  }

  String _extractJson(String content) {
    final startIndex = content.indexOf('{');
    final endIndex = content.lastIndexOf('}');
    if (startIndex == -1 || endIndex == -1 || endIndex < startIndex) {
      return '{}';
    }
    return content.substring(startIndex, endIndex + 1);
  }

  String _markTypeToString(MarkType type) {
    switch (type) {
      case MarkType.highlight:
        return '高亮';
      case MarkType.underline:
        return '下划线';
      case MarkType.circle:
        return '圈选';
    }
  }
}
