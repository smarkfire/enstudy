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
import 'package:enstudy/features/auth/presentation/providers/auth_provider.dart';
import 'package:enstudy/features/cards/data/models/card_model.dart';
import 'package:enstudy/features/cards/domain/entities/card.dart' as domain;
import 'package:enstudy/features/upload/data/datasources/qwen_vl_service.dart';
import 'package:enstudy/features/upload/data/models/upload_result.dart';
import 'package:enstudy/features/upload/domain/entities/ocr_result.dart';

enum UploadStatus {
  idle,
  pickingImage,
  compressing,
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
  final List<int>? imageBytes;
  final UploadResult? uploadResult;
  final Set<String> selectedCardIds;

  const UploadState({
    this.status = UploadStatus.idle,
    this.errorMessage,
    this.imagePath,
    this.imageBytes,
    this.uploadResult,
    this.selectedCardIds = const {},
  });

  UploadState copyWith({
    UploadStatus? status,
    String? errorMessage,
    String? imagePath,
    List<int>? imageBytes,
    UploadResult? uploadResult,
    Set<String>? selectedCardIds,
  }) =>
      UploadState(
        status: status ?? this.status,
        errorMessage: errorMessage,
        imagePath: imagePath ?? this.imagePath,
        imageBytes: imageBytes ?? this.imageBytes,
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

final qwenVlServiceProvider = Provider<QwenVlService>((ref) {
  return QwenVlService(ref.watch(dioProvider));
});

final uploadProvider =
    StateNotifierProvider<UploadNotifier, UploadState>((ref) {
  return UploadNotifier(
    ref: ref,
    qwenVlService: ref.watch(qwenVlServiceProvider),
    cardDao: ref.watch(cardDaoProvider),
    sourceDao: ref.watch(sourceDaoProvider),
  );
});

class UploadNotifier extends StateNotifier<UploadState> {
  final Ref _ref;
  final QwenVlService _qwenVlService;
  final CardDao _cardDao;
  final SourceDao _sourceDao;
  final ImagePicker _imagePicker = ImagePicker();
  final _uuid = const Uuid();
  final _secureStorage = const FlutterSecureStorage();

  UploadNotifier({
    required Ref ref,
    required QwenVlService qwenVlService,
    required CardDao cardDao,
    required SourceDao sourceDao,
  })  : _ref = ref,
        _qwenVlService = qwenVlService,
        _cardDao = cardDao,
        _sourceDao = sourceDao,
        super(const UploadState());

  Future<String> _getQwenApiKey() async {
    final stored = await _secureStorage.read(key: 'qwen_api_key');
    return stored?.isNotEmpty == true ? stored! : ApiConfig.qwenApiKey;
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

  Future<void> pickImage() async {
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

      List<int> imageBytes;
      if (kIsWeb) {
        imageBytes = await pickedFile.readAsBytes();
      } else {
        final compressedFile = await ImageCompressor.compressToFile(
          sourcePath: imagePath,
          maxWidth: 1920,
          maxHeight: 1080,
          quality: 80,
        );
        imageBytes = await compressedFile.readAsBytes();
      }

      if (imageBytes.isEmpty) {
        state = state.copyWith(
          status: UploadStatus.error,
          errorMessage: '图片读取失败，请重新选择',
        );
        return;
      }

      state = state.copyWith(
        status: UploadStatus.readyToAnalyze,
        imageBytes: imageBytes,
      );
    } catch (e) {
      state = state.copyWith(
        status: UploadStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> analyzeWithDefault() async {
    final imageBytes = state.imageBytes;
    if (imageBytes == null) return;

    await _performAnalysis(imageBytes: imageBytes);
  }

  Future<void> analyzeWithCustomPrompt(String userPrompt) async {
    final imageBytes = state.imageBytes;
    if (imageBytes == null) return;

    await _performAnalysis(imageBytes: imageBytes, customPrompt: userPrompt);
  }

  Future<void> _performAnalysis({
    required List<int> imageBytes,
    String? customPrompt,
  }) async {
    try {
      final authState = _ref.read(authProvider);
      if (authState.isLoggedIn && authState.aiQuota <= 0) {
        state = state.copyWith(
          status: UploadStatus.error,
          errorMessage: 'AI使用次数不足，请在"我的"页面购买更多次数',
        );
        return;
      }

      final apiKey = await _getQwenApiKey();

      if (apiKey.isEmpty) {
        state = state.copyWith(
          status: UploadStatus.error,
          errorMessage: '未配置千问 API Key，请在设置页配置',
        );
        return;
      }

      state = state.copyWith(status: UploadStatus.analyzing);

      AiAnalysisResult aiResult;
      try {
        aiResult = await _qwenVlService.analyzeImage(
          imageBytes: imageBytes,
          apiKey: apiKey,
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

      if (aiResult.markedAnalysis.isEmpty && aiResult.recommendations.isEmpty) {
        state = state.copyWith(
          status: UploadStatus.error,
          errorMessage: 'AI分析未返回有效结果，请重试',
        );
        return;
      }

      final sourceId = _uuid.v4();
      final uploadResult = UploadResult(
        sourceId: sourceId,
        ocrResult: const OcrResult(text: ''),
        matchResult: const MatchResult(),
        aiAnalysisResult: aiResult,
      );

      final defaultSelected = <String>{};
      for (final item in aiResult.markedAnalysis) {
        defaultSelected.add('marked_${item.content}');
      }

      state = state.copyWith(
        status: UploadStatus.previewing,
        uploadResult: uploadResult,
        selectedCardIds: defaultSelected,
      );

      if (authState.isLoggedIn) {
        await _ref.read(authProvider.notifier).consumeAiQuota();
      }
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

  void editCard(
    String cardId, {
    String? content,
    String? translation,
    String? phonetic,
    String? example,
    String? exampleTranslation,
  }) {
    final result = state.uploadResult;
    if (result == null) return;

    final newMarkedAnalysis =
        result.aiAnalysisResult.markedAnalysis.map((item) {
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

    final newRecommendations =
        result.aiAnalysisResult.recommendations.map((item) {
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

  Future<int> saveSelectedCards() async {
    if (state.uploadResult == null) return 0;

    state = state.copyWith(status: UploadStatus.saving);

    try {
      final result = state.uploadResult!;
      final selectedIds = state.selectedCardIds;

      await _sourceDao.insertSource(
        SourcesCompanion(
          id: Value(result.sourceId),
          imagePath: Value(state.imagePath ?? ''),
          createdAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );

      final cardsToSave = <domain.Card>[];
      final now = DateTime.now();

      for (final item in result.aiAnalysisResult.markedAnalysis) {
        final id = 'marked_${item.content}';
        if (selectedIds.contains(id)) {
          cardsToSave.add(
            domain.Card(
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
            ),
          );
        }
      }

      for (final item in result.aiAnalysisResult.recommendations) {
        final id = 'rec_${item.content}';
        if (selectedIds.contains(id)) {
          cardsToSave.add(
            domain.Card(
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
            ),
          );
        }
      }

      for (final card in cardsToSave) {
        await _cardDao.insertCard(card.toCompanion());
      }

      state = state.copyWith(status: UploadStatus.idle);
      return cardsToSave.length;
    } catch (e) {
      state = state.copyWith(
        status: UploadStatus.error,
        errorMessage: e.toString(),
      );
      return -1;
    }
  }

  void reset() {
    state = const UploadState();
  }
}
