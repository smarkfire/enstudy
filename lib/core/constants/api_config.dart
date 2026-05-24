import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get qwenApiKey =>
      dotenv.env['QWEN_API_KEY'] ?? '';

  static String get corsProxyUrl =>
      dotenv.env['CORS_PROXY_URL'] ?? '';

  static String get adminWechatIds =>
      dotenv.env['ADMIN_WECHAT_IDS'] ?? '';
}
