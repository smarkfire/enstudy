import 'package:drift/drift.dart';
import 'package:enstudy/core/database/app_database.dart';
import 'package:enstudy/features/auth/domain/entities/user.dart' as domain;

extension UserRowX on UserRow {
  domain.User toEntity() => domain.User(
        id: id,
        wechatId: wechatId,
        nickname: nickname,
        avatarUrl: avatarUrl,
        aiQuota: aiQuota,
        createdAt: createdAt != null
            ? DateTime.fromMillisecondsSinceEpoch(createdAt!)
            : null,
      );
}

extension UserEntityX on domain.User {
  UsersCompanion toCompanion() => UsersCompanion(
        id: Value(id),
        wechatId: Value(wechatId),
        nickname: Value(nickname),
        avatarUrl: Value(avatarUrl),
        aiQuota: Value(aiQuota),
        createdAt: Value(createdAt?.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch),
      );
}
