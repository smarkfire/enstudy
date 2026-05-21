import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CorsProxyInterceptor extends Interceptor {
  final String proxyUrl;

  CorsProxyInterceptor({required this.proxyUrl});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!kIsWeb || proxyUrl.isEmpty) {
      handler.next(options);
      return;
    }

    final originalUrl = options.uri.toString();
    final proxiedUrl = '$proxyUrl$originalUrl';

    options.path = proxiedUrl;
    options.queryParameters.clear();

    handler.next(options);
  }
}
