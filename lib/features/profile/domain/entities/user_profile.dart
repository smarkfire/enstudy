import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

@Freezed()
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    @Default(0) int totalScore,
    @Default(1) int level,
    @Default(0) int streakDays,
    DateTime? lastCheckin,
    @Default(10) int newCardsPerDay,
    @Default('08:00') String remindTime,
  }) = _UserProfile;

  const UserProfile._();

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}
