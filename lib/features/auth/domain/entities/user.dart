import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@Freezed()
class User with _$User {
  const factory User({
    required String id,
    String? phone,
    String? wechatId,
    @Default('') String nickname,
    @Default('') String avatarUrl,
    @Default(0) int aiQuota,
    @Default(0) int totalScore,
    @Default(1) int level,
    @Default(false) bool isAdmin,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) = _User;

  const User._();

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  factory User.fromApiJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      phone: json['phone'],
      nickname: json['nickname'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
      aiQuota: json['ai_quota'] ?? 0,
      totalScore: json['total_score'] ?? 0,
      level: json['level'] ?? 1,
      isAdmin: json['is_admin'] ?? false,
    );
  }
}
