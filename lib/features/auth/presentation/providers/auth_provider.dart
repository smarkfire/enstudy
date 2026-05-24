import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import 'package:enstudy/core/constants/api_config.dart';
import 'package:enstudy/core/database/app_database.dart';
import 'package:enstudy/core/database/daos/user_dao.dart';
import 'package:enstudy/features/upload/presentation/providers/upload_provider.dart';
import 'package:enstudy/features/auth/data/models/user_model.dart';
import 'package:enstudy/features/auth/domain/entities/user.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isLoggedIn => user != null;
  bool get isAdmin => user?.isAdmin ?? false;
  int get aiQuota => user?.aiQuota ?? 0;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) =>
      AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

final userDaoProvider = Provider<UserDao>((ref) {
  return UserDao(ref.watch(appDatabaseProvider));
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(userDaoProvider));
});

class AuthNotifier extends StateNotifier<AuthState> {
  final UserDao _userDao;
  final _secureStorage = const FlutterSecureStorage();
  final _uuid = const Uuid();

  AuthNotifier(this._userDao) : super(const AuthState()) {
    _restoreLogin();
  }

  Future<void> _restoreLogin() async {
    final userId = await _secureStorage.read(key: 'current_user_id');
    if (userId == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final userRow = await _userDao.getUserById(userId);
      if (userRow != null) {
        final user = userRow.toEntity();
        final adminIds = _getAdminIds();
        final isAdmin = adminIds.contains(user.wechatId);
        state = state.copyWith(
          user: user.copyWith(isAdmin: isAdmin),
          isLoading: false,
        );
      } else {
        await _secureStorage.delete(key: 'current_user_id');
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      debugPrint('Restore login error: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loginWithWechat() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final wechatId = 'demo_user_${DateTime.now().millisecondsSinceEpoch}';
      final nickname = '微信用户';
      final avatarUrl = '';

      await _loginOrRegister(wechatId, nickname, avatarUrl);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '登录失败：$e',
      );
    }
  }

  Future<void> loginWithWechatId(String wechatId, {String nickname = '', String avatarUrl = ''}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _loginOrRegister(wechatId, nickname.isNotEmpty ? nickname : '用户$wechatId', avatarUrl);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '登录失败：$e',
      );
    }
  }

  Future<void> _loginOrRegister(String wechatId, String nickname, String avatarUrl) async {
    final adminIds = _getAdminIds();
    final isAdmin = adminIds.contains(wechatId);

    var userRow = await _userDao.getUserByWechatId(wechatId);

    if (userRow != null) {
      await _userDao.updateLastLogin(userRow.id);
      userRow = await _userDao.getUserById(userRow.id);
      if (userRow != null) {
        final user = userRow.toEntity().copyWith(isAdmin: isAdmin);
        await _secureStorage.write(key: 'current_user_id', value: user.id);
        state = state.copyWith(user: user, isLoading: false);
      }
    } else {
      final id = _uuid.v4();
      final now = DateTime.now();
      final newUser = User(
        id: id,
        wechatId: wechatId,
        nickname: nickname,
        avatarUrl: avatarUrl,
        aiQuota: 10,
        isAdmin: isAdmin,
        createdAt: now,
      );
      await _userDao.insertUser(newUser.toCompanion());
      await _secureStorage.write(key: 'current_user_id', value: id);
      state = state.copyWith(user: newUser, isLoading: false);
    }
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: 'current_user_id');
    state = const AuthState();
  }

  Future<bool> consumeAiQuota() async {
    final user = state.user;
    if (user == null) return false;
    if (user.aiQuota <= 0) return false;

    final success = await _userDao.decrementAiQuotaIfAvailable(user.id);
    if (success) {
      state = state.copyWith(
        user: user.copyWith(aiQuota: user.aiQuota - 1),
      );
    }
    return success;
  }

  Future<void> refreshUser() async {
    final user = state.user;
    if (user == null) return;
    final userRow = await _userDao.getUserById(user.id);
    if (userRow != null) {
      final adminIds = _getAdminIds();
      final isAdmin = adminIds.contains(userRow.wechatId);
      state = state.copyWith(user: userRow.toEntity().copyWith(isAdmin: isAdmin));
    }
  }

  List<String> _getAdminIds() {
    final ids = ApiConfig.adminWechatIds;
    if (ids.isEmpty) return [];
    return ids.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }
}
