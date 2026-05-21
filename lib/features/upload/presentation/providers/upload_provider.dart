import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import 'package:enstudy/core/constants/api_config.dart';
import 'package:enstudy/core/database/app_database.dart';
import 'package:enstudy/core/database/daos/card_dao.dart';
import 'package:enstudy/core/database/daos/source_dao.dart';
import 'package:enstudy/core/database/database_setup.dart';
import 'package:enstudy/core/network/cors_proxy_interceptor.dart';
import 'package:enstudy/core/utils/image_compressor.dart';
import 'package:enstudy/features/cards/data/models/card_model.dart';
import 'package:enstudy/features/cards/domain/entities/card.dart' as domain;
import 'package:enstudy/features/upload/data/datasources/ai_analysis_service.dart';
import 'package:enstudy/features/upload/data/datasources/mark_detector_service.dart';
import 'package:enstudy/features/upload/data/datasources/mark_matcher.dart';
import 'package:enstudy/features/upload/data/datasources/ocr_service.dart';
import 'package:enstudy/features/upload/data/models/upload_result.dart';
import 'package:enstudy/features/upload/domain/entities/ocr_result.dart';

enum UploadStatus {
  idle,
  pickingImage,
  compressing,
  recognizing,
  readyToAnalyze,
  analyzing,
  previewing,
  saving,
  error,
}

class UploadState {
  final UploadStatus status;
  final String? errorMessage;
  final String? imagePath;
  final List<int>? compressedBytes;
  final OcrResult? ocrResult;
  final MatchResult? matchResult;
  final UploadResult? uploadResult;
  final Set<String> selectedCardIds;

  const UploadState({
    this.status = UploadStatus.idle,
    this.errorMessage,
    this.imagePath,
    this.compressedBytes,
    this.ocrResult,
    this.matchResult,
    this.uploadResult,
    this.selectedCardIds = const {},
  });

  UploadState copyWith({
    UploadStatus? status,
    String? errorMessage,
    String? imagePath,
    List<int>? compressedBytes,
    OcrResult? ocrResult,
    MatchResult? matchResult,
    UploadResult? uploadResult,
    Set<String>? selectedCardIds,
  }) =>
      UploadState(
        status: status ?? this.status,
        errorMessage: errorMessage,
        imagePath: imagePath ?? this.imagePath,
        compressedBytes: compressedBytes ?? this.compressedBytes,
        ocrResult: ocrResult ?? this.ocrResult,
        matchResult: matchResult ?? this.matchResult,
        uploadResult: uploadResult ?? this.uploadResult,
        selectedCardIds: selectedCardIds ?? this.selectedCardIds,
      );
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return createDatabase();
});

final cardDaoProvider = Provider<CardDao>((ref) {
  return CardDao(ref.watch(appDatabaseProvider));
});

final sourceDaoProvider = Provider<SourceDao>((ref) {
  return SourceDao(ref.watch(appDatabaseProvider));
});

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  if (kIsWeb) {
    final proxyUrl = ApiConfig.corsProxyUrl;
    if (proxyUrl.isNotEmpty) {
      dio.interceptors.add(CorsProxyInterceptor(proxyUrl: proxyUrl));
    }
  }
  return dio;
});

final ocrServiceProvider = Provider<BaiduOcrService>((ref) {
  return BaiduOcrService(ref.watch(dioProvider));
});

final aiServiceProvider = Provider<DeepSeekAiService>((ref) {
  return DeepSeekAiService(ref.watch(dioProvider));
});

final markDetectorServiceProvider = Provider<MarkDetectorService>((ref) {
  return MarkDetectorService();
});

final markMatcherProvider = Provider<MarkMatcher>((ref) {
  return MarkMatcher();
});

final uploadProvider =
    StateNotifierProvider<UploadNotifier, UploadState>((ref) {
  return UploadNotifier(
    ocrService: ref.watch(ocrServiceProvider),
    aiService: ref.watch(aiServiceProvider),
    markDetectorService: ref.watch(markDetectorServiceProvider),
    markMatcher: ref.watch(markMatcherProvider),
    cardDao: ref.watch(cardDaoProvider),
    sourceDao: ref.watch(sourceDaoProvider),
  );
});

class UploadNotifier extends StateNotifier<UploadState> {
  final BaiduOcrService _ocrService;
  final DeepSeekAiService _aiService;
  final MarkDetectorService _markDetectorService;
  final MarkMatcher _markMatcher;
  final CardDao _cardDao;
  final SourceDao _sourceDao;
  final ImagePicker _imagePicker = ImagePicker();
  final _uuid = const Uuid();
  final _secureStorage = const FlutterSecureStorage();

  UploadNotifier({
    required BaiduOcrService ocrService,
    required DeepSeekAiService aiService,
    required MarkDetectorService markDetectorService,
    required MarkMatcher markMatcher,
    required CardDao cardDao,
    required SourceDao sourceDao,
  })  : _ocrService = ocrService,
        _aiService = aiService,
        _markDetectorService = markDetectorService,
        _markMatcher = markMatcher,
        _cardDao = cardDao,
        _sourceDao = sourceDao,
        super(const UploadState());

  Future<String> _getBaiduApiKey() async {
    final stored = await _secureStorage.read(key: 'baidu_ocr_api_key');
    return stored?.isNotEmpty == true ? stored! : ApiConfig.baiduOcrApiKey;
  }

  Future<String> _getBaiduSecretKey() async {
    final stored = await _secureStorage.read(key: 'baidu_ocr_secret_key');
    return stored?.isNotEmpty == true ? stored! : ApiConfig.baiduOcrSecretKey;
  }

  Future<String> _getDeepSeekApiKey() async {
    final stored = await _secureStorage.read(key: 'deepseek_api_key');
    return stored?.isNotEmpty == true ? stored! : ApiConfig.deepseekApiKey;
  }

  Future<String> _getCorsProxyUrl() async {
    final stored = await _secureStorage.read(key: 'cors_proxy_url');
    return stored?.isNotEmpty == true ? stored! : ApiConfig.corsProxyUrl;
  }

  String _formatDioError(DioException e, String context) {
    if (kIsWeb && e.type == DioExceptionType.connectionError) {
      return '$context失败：浏览器跨域(CORS)限制\n'
          '解决方案：\n'
          '1. 在设置页配置 CORS 代理地址\n'
          '2. 或使用 flutter run -d chrome --web-browser-flag=--disable-web-security 运行';
    }
    if (e.type == DioExceptionType.connectionError) {
      return '$context失败：网络连接错误，请检查网络';
    }
    if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
      return '$context失败：API Key 无效或已过期，请在设置页检查配置';
    }
    return '$context失败：${e.message ?? e.type.name}';
  }

  Future<void> pickAndRecognizeImage() async {
    try {
      state = state.copyWith(status: UploadStatus.pickingImage);

      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (pickedFile == null) {
        state = state.copyWith(status: UploadStatus.idle);
        return;
      }

      final imagePath = pickedFile.path;
      state = state.copyWith(
        status: UploadStatus.compressing,
        imagePath: imagePath,
      );

      List<int> compressedBytes;
      if (kIsWeb) {
        compressedBytes = await pickedFile.readAsBytes();
      } else {
        final compressedFile = await ImageCompressor.compressToFile(
          sourcePath: imagePath,
          maxWidth: 1920,
          maxHeight: 1080,
          quality: 80,
        );
        compressedBytes = await compressedFile.readAsBytes();
      }

      if (compressedBytes.isEmpty) {
        state = state.copyWith(
          status: UploadStatus.error,
          errorMessage: '图片读取失败，请重新选择',
        );
        return;
      }

      final baiduApiKey = await _getBaiduApiKey();
      final baiduSecretKey = await _getBaiduSecretKey();

      state = state.copyWith(status: UploadStatus.recognizing);

      OcrResult ocrResult;
      try {
        final accessToken = await _ocrService.getAccessToken(
          baiduApiKey,
          baiduSecretKey,
        );
        ocrResult = await _ocrService.recognizeText(
          compressedBytes,
          accessToken,
        );
      } on DioException catch (e) {
        final msg = _formatDioError(e, 'OCR识别');
        state = state.copyWith(
          status: UploadStatus.error,
          errorMessage: msg,
        );
        return;
      } catch (e) {
        state = state.copyWith(
          status: UploadStatus.error,
          errorMessage: 'OCR识别失败：$e',
        );
        return;
      }

      if (ocrResult.words.isEmpty && ocrResult.text.isEmpty) {
        state = state.copyWith(
          status: UploadStatus.error,
          errorMessage: '未识别到文字，请确保图片包含英文内容',
        );
        return;
      }

      List<MarkRegion> markRegions = [];
      if (!kIsWeb) {
        try {
          markRegions = await _markDetectorService.detectMarks(compressedBytes);
        } catch (_) {}
      }
      final matchResult = _markMatcher.match(ocrResult, markRegions);

      state = state.copyWith(
        status: UploadStatus.readyToAnalyze,
        compressedBytes: compressedBytes,
        ocrResult: ocrResult,
        matchResult: matchResult,
      );
    } catch (e) {
      state = state.copyWith(
        status: UploadStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> analyzeWithDefault() async {
    final ocrResult = state.ocrResult;
    final matchResult = state.matchResult;
    if (ocrResult == null || matchResult == null) return;

    await _performAnalysis(
      ocrText: ocrResult.text,
      markedContents: matchResult.markedContents.map((mc) => mc.text).toList(),
      markTypes: matchResult.markedContents.map((mc) => mc.markType).toList(),
    );
  }

  Future<void> analyzeWithCustomPrompt(String userPrompt) async {
    final ocrResult = state.ocrResult;
    if (ocrResult == null) return;

    await _performAnalysis(
      ocrText: ocrResult.text,
      customPrompt: userPrompt,
    );
  }

  Future<void> _performAnalysis({
    required String ocrText,
    List<String>? markedContents,
    List<MarkType>? markTypes,
    String? customPrompt,
  }) async {
    try {
      final deepseekApiKey = await _getDeepSeekApiKey();

      state = state.copyWith(status: UploadStatus.analyzing);

      AiAnalysisResult aiAnalysisResult;
      try {
        aiAnalysisResult = await _aiService.analyze(
          ocrText: ocrText,
          markedContents: markedContents ?? [],
          markTypes: markTypes ?? [],
          apiKey: deepseekApiKey,
          customPrompt: customPrompt,
        );
      } on DioException catch (e) {
        final msg = _formatDioError(e, 'AI分析');
        state = state.copyWith(
          status: UploadStatus.error,
          errorMessage: msg,
        );
        return;
      } catch (e) {
        state = state.copyWith(
          status: UploadStatus.error,
          errorMessage: 'AI分析失败：$e',
        );
        return;
      }

      final sourceId = _uuid.v4();
      final uploadResult = UploadResult(
        sourceId: sourceId,
        ocrResult: state.ocrResult!,
        matchResult: state.matchResult ?? const MatchResult(),
        aiAnalysisResult: aiAnalysisResult,
      );

      final defaultSelected = <String>{};
      for (final item in aiAnalysisResult.markedAnalysis) {
        defaultSelected.add('marked_${item.content}');
      }

      if (aiAnalysisResult.markedAnalysis.isEmpty &&
          aiAnalysisResult.recommendations.isEmpty) {
        state = state.copyWith(
          status: UploadStatus.error,
          errorMessage: 'AI分析未返回有效结果，请重试',
        );
        return;
      }

      state = state.copyWith(
        status: UploadStatus.previewing,
        uploadResult: uploadResult,
        selectedCardIds: defaultSelected,
      );
    } catch (e) {
      state = state.copyWith(
        status: UploadStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void toggleCardSelection(String cardId) {
    final selected = Set<String>.from(state.selectedCardIds);
    if (selected.contains(cardId)) {
      selected.remove(cardId);
    } else {
      selected.add(cardId);
    }
    state = state.copyWith(selectedCardIds: selected);
  }

  void editCard(String cardId, {
    String? content,
    String? translation,
    String? phonetic,
    String? example,
    String? exampleTranslation,
  }) {
    final result = state.uploadResult;
    if (result == null) return;

    final newMarkedAnalysis = result.aiAnalysisResult.markedAnalysis.map((item) {
      if ('marked_${item.content}' == cardId) {
        return item.copyWith(
          content: content ?? item.content,
          translation: translation ?? item.translation,
          phonetic: phonetic ?? item.phonetic,
          example: example ?? item.example,
          exampleTranslation: exampleTranslation ?? item.exampleTranslation,
        );
      }
      return item;
    }).toList();

    final newRecommendations = result.aiAnalysisResult.recommendations.map((item) {
      if ('rec_${item.content}' == cardId) {
        return item.copyWith(
          content: content ?? item.content,
          translation: translation ?? item.translation,
          phonetic: phonetic ?? item.phonetic,
          example: example ?? item.example,
          exampleTranslation: exampleTranslation ?? item.exampleTranslation,
        );
      }
      return item;
    }).toList();

    final newAiResult = result.aiAnalysisResult.copyWith(
      markedAnalysis: newMarkedAnalysis,
      recommendations: newRecommendations,
    );

    state = state.copyWith(
      uploadResult: result.copyWith(aiAnalysisResult: newAiResult),
    );
  }

  Future<void> saveSelectedCards() async {
    if (state.uploadResult == null) return;

    state = state.copyWith(status: UploadStatus.saving);

    try {
      final result = state.uploadResult!;
      final selectedIds = state.selectedCardIds;

      await _sourceDao.insertSource(SourcesCompanion(
        id: Value(result.sourceId),
        imagePath: Value(state.imagePath ?? ''),
        createdAt: Value(DateTime.now().millisecondsSinceEpoch),
      ));

      final cardsToSave = <domain.Card>[];
      final now = DateTime.now();

      for (final item in result.aiAnalysisResult.markedAnalysis) {
        final id = 'marked_${item.content}';
        if (selectedIds.contains(id)) {
          cardsToSave.add(domain.Card(
            id: _uuid.v4(),
            type: 'word',
            content: item.content,
            translation: item.translation,
            phonetic: item.phonetic,
            example: item.example,
            exampleTranslation: item.exampleTranslation,
            sourceId: result.sourceId,
            createdAt: now,
            nextReview: now,
          ));
        }
      }

      for (final item in result.aiAnalysisResult.recommendations) {
        final id = 'rec_${item.content}';
        if (selectedIds.contains(id)) {
          cardsToSave.add(domain.Card(
            id: _uuid.v4(),
            type: item.type,
            content: item.content,
            translation: item.translation,
            phonetic: item.phonetic,
            example: item.example,
            exampleTranslation: item.exampleTranslation,
            sourceId: result.sourceId,
            createdAt: now,
            nextReview: now,
          ));
        }
      }

      for (final card in cardsToSave) {
        await _cardDao.insertCard(card.toCompanion());
      }

      state = state.copyWith(status: UploadStatus.idle);
    } catch (e) {
      state = state.copyWith(
        status: UploadStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() {
    state = const UploadState();
  }
}
