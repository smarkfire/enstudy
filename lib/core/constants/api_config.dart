import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baiduOcrApiKey =>
      dotenv.env['BAIDU_OCR_API_KEY'] ?? '';

  static String get baiduOcrSecretKey =>
      dotenv.env['BAIDU_OCR_SECRET_KEY'] ?? '';

  static String get deepseekApiKey =>
      dotenv.env['DEEPSEEK_API_KEY'] ?? '';

  static String get corsProxyUrl =>
      dotenv.env['CORS_PROXY_URL'] ?? '';
}
