class AppConstants {
  AppConstants._();

  static const String appName = 'EnStudy';
  static const String appNameCn = '英语学习';
  static const String appVersion = '1.0.0';
  static const int appBuildNumber = 1;

  static const String dbName = 'enstudy.db';
  static const String sharedPreferencesKey = 'enstudy_prefs';

  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration splashDuration = Duration(seconds: 2);

  static const int maxCardsPerDay = 50;
  static const int maxUploadSizeMB = 20;
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'webp'];
  static const List<String> supportedAudioFormats = ['mp3', 'wav', 'aac', 'm4a'];
}
