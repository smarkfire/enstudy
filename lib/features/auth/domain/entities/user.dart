import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@Freezed()
class User with _$User {
  const factory User({
    required String id,
    required String wechatId,
    @Default('') String nickname,
    @Default('') String avatarUrl,
    @Default(0) int aiQuota,
    @Default(false) bool isAdmin,
    DateTime? createdAt,
  }) = _User;

  const User._();

  factory User.fromJson(Map<String, dynamic> json) =>
      _$UserFromJson(json);
}
