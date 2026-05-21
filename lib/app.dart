import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enstudy/core/constants/app_constants.dart';
import 'package:enstudy/core/router/app_router.dart';
import 'package:enstudy/core/theme/app_theme.dart';

class EnStudyApp extends ConsumerStatefulWidget {
  const EnStudyApp({super.key});

  @override
  ConsumerState<EnStudyApp> createState() => _EnStudyAppState();
}

class _EnStudyAppState extends ConsumerState<EnStudyApp> {
  @override
  void initState() {
    super.initState();

    if (!kIsWeb) {
      _initNotifications();
    }
  }

  Future<void> _initNotifications() async {
    // Notification listeners are platform-specific
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
