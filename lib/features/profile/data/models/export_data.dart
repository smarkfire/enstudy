class ExportData {
  final String version;
  final String exportTime;
  final String appVersion;
  final List<Map<String, dynamic>> cards;
  final List<Map<String, dynamic>> sources;
  final List<Map<String, dynamic>> reviewLogs;
  final List<Map<String, dynamic>> gameSessions;
  final Map<String, dynamic>? userProfile;

  const ExportData({
    required this.version,
    required this.exportTime,
    required this.appVersion,
    required this.cards,
    required this.sources,
    required this.reviewLogs,
    required this.gameSessions,
    this.userProfile,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'exportTime': exportTime,
        'appVersion': appVersion,
        'cards': cards,
        'sources': sources,
        'reviewLogs': reviewLogs,
        'gameSessions': gameSessions,
        'userProfile': userProfile,
      };

  factory ExportData.fromJson(Map<String, dynamic> json) => ExportData(
        version: json['version'] as String,
        exportTime: json['exportTime'] as String,
        appVersion: json['appVersion'] as String,
        cards: (json['cards'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        sources: (json['sources'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        reviewLogs: (json['reviewLogs'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        gameSessions: (json['gameSessions'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        userProfile: json['userProfile'] != null
            ? Map<String, dynamic>.from(json['userProfile'] as Map)
            : null,
      );
}
