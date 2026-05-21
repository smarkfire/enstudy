import 'package:drift/drift.dart';
import 'package:enstudy/core/database/app_database.dart';
import 'package:enstudy/features/profile/domain/entities/user_profile.dart' as domain;

extension UserProfileRowX on UserProfileRow {
  domain.UserProfile toEntity() => domain.UserProfile(
        id: id,
        totalScore: totalScore,
        level: level,
        streakDays: streakDays,
        lastCheckin: lastCheckin != null
            ? DateTime.fromMillisecondsSinceEpoch(lastCheckin!)
            : null,
        newCardsPerDay: newCardsPerDay,
        remindTime: remindTime,
      );
}

extension UserProfileEntityX on domain.UserProfile {
  UserProfilesCompanion toCompanion() => UserProfilesCompanion(
        id: Value(id),
        totalScore: Value(totalScore),
        level: Value(level),
        streakDays: Value(streakDays),
        lastCheckin: Value(lastCheckin?.millisecondsSinceEpoch),
        newCardsPerDay: Value(newCardsPerDay),
        remindTime: Value(remindTime),
      );

  UserProfileRow toRow() => UserProfileRow(
        id: id,
        totalScore: totalScore,
        level: level,
        streakDays: streakDays,
        lastCheckin: lastCheckin?.millisecondsSinceEpoch,
        newCardsPerDay: newCardsPerDay,
        remindTime: remindTime,
      );
}
