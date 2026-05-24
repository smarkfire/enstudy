import 'package:drift/drift.dart';
import '../app_database.dart';

part 'user_dao.g.dart';

@DriftAccessor(tables: [Users])
class UserDao extends DatabaseAccessor<AppDatabase>
    with _$UserDaoMixin {
  UserDao(super.db);

  Future<UserRow?> getUserById(String id) =>
      (select(users)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<UserRow?> getUserByWechatId(String wechatId) =>
      (select(users)..where((t) => t.wechatId.equals(wechatId)))
          .getSingleOrNull();

  Future<void> insertUser(Insertable<UserRow> user) =>
      into(users).insertOnConflictUpdate(user);

  Future<void> updateLastLogin(String id) =>
      (update(users)..where((t) => t.id.equals(id))).write(
        UsersCompanion(
          lastLoginAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );

  Future<bool> decrementAiQuotaIfAvailable(String id) async {
    final user = await getUserById(id);
    if (user == null || user.aiQuota <= 0) return false;

    await (update(users)..where((t) => t.id.equals(id))).write(
      UsersCompanion(aiQuota: Value(user.aiQuota - 1)),
    );
    return true;
  }

  Future<void> updateAiQuota(String id, int quota) =>
      (update(users)..where((t) => t.id.equals(id))).write(
        UsersCompanion(aiQuota: Value(quota)),
      );

  Stream<List<UserRow>> watchAllUsers() =>
      (select(users)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
}
