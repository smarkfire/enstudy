import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:enstudy/features/upload/domain/entities/ocr_result.dart';

class QwenVlService {
  final Dio _dio;

  QwenVlService(this._dio);

  static const String _baseUrl =
      'https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions';

  Future<AiAnalysisResult> analyzeImage({
    required List<int> imageBytes,
    required String apiKey,
    String? customPrompt,
  }) async {
    final base64Image = base64Encode(imageBytes);
    final imageUrl = 'data:image/jpeg;base64,$base64Image';

    final prompt = customPrompt != null && customPrompt.isNotEmpty
        ? _buildCustomPrompt(customPrompt)
        : _buildDefaultPrompt();

    final response = await _dio.post(
      _baseUrl,
      options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      ),
      data: {
        'model': 'qwen3.5-omni-flash',
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image_url',
                'image_url': {'url': imageUrl}
              },
              {'type': 'text', 'text': prompt},
            ],
          },
        ],
        'temperature': 0.3,
        'max_tokens': 4096,
      },
    );

    final choices = response.data['choices'] as List<dynamic>;
    if (choices.isEmpty) {
      return const AiAnalysisResult();
    }

    final content = choices[0]['message']['content'] as String;
    debugPrint('===== Qwen VL Raw Response =====');
    debugPrint(content);
    debugPrint('================================');
    return _parseAiResponse(content);
  }

  String _buildDefaultPrompt() {
    return '''你是一个英语学习助手。请仔细观察这张英语学习材料的图片。

请完成以下任务：
1. 识别图片中所有被划线标注、高亮标记或圈出的单词/短语——这些是学生不认识的内容
2. 如果图片中有错题标记（如叉号、红圈等），也识别出来
3. 从图片中额外推荐最多3个学生可能不认识的重要单词/短语

对每个识别到的内容，提供：中文翻译、音标（单词类型）、例句和例句翻译。

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
- marked_analysis 放图片中标记的（划线、高亮、圈出、错题）内容
- recommendations 放你额外推荐的内容
- 严格返回JSON，不要添加其他文字''';
  }

  String _buildCustomPrompt(String userPrompt) {
    return '''你是一个英语学习助手。请仔细观察这张英语学习材料的图片。

用户的自定义要求：
$userPrompt

请根据用户的要求分析图片内容，提取英语学习卡片。每张卡片包含：内容、翻译、音标、例句、例句翻译。

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
        markedAnalysis.add(
          MarkedAnalysisItem(
            content: item['content'] as String? ?? '',
            translation: item['translation'] as String? ?? '',
            phonetic: item['phonetic'] as String? ?? '',
            example: item['example'] as String? ?? '',
            exampleTranslation: item['example_translation'] as String? ?? '',
          ),
        );
      }

      final recommendations = <RecommendationItem>[];
      final recList = json['recommendations'] as List<dynamic>? ?? [];
      for (final item in recList) {
        recommendations.add(
          RecommendationItem(
            content: item['content'] as String? ?? '',
            translation: item['translation'] as String? ?? '',
            phonetic: item['phonetic'] as String? ?? '',
            example: item['example'] as String? ?? '',
            exampleTranslation: item['example_translation'] as String? ?? '',
            type: item['type'] as String? ?? 'word',
            reason: item['reason'] as String? ?? '',
          ),
        );
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
}
