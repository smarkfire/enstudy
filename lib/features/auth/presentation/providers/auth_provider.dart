import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:enstudy/core/network/api_client.dart';
import 'package:enstudy/features/auth/data/services/auth_service.dart';
import 'package:enstudy/features/profile/data/services/user_service.dart';
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

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authServiceProvider),
    ref.watch(userServiceProvider),
  );
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final UserService _userService;
  final _secureStorage = const FlutterSecureStorage();
  final _apiClient = ApiClient();

  AuthNotifier(this._authService, this._userService) : super(const AuthState()) {
    _restoreLogin();
  }

  Future<void> _restoreLogin() async {
    final token = await _secureStorage.read(key: 'auth_token');
    if (token == null) return;

    _apiClient.setToken(token);
    state = state.copyWith(isLoading: true);
    try {
      final profileData = await _userService.getProfile();
      final user = User.fromApiJson(profileData);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      debugPrint('Restore login error: $e');
      await _clearLogin();
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> sendVerificationCode(String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.sendVerificationCode(phone);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> login(String phone, String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _authService.login(phone, code);
      _apiClient.setToken(result.token);
      await _secureStorage.write(key: 'auth_token', value: result.token);
      state = state.copyWith(user: result.user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    await _clearLogin();
    state = const AuthState();
  }

  Future<void> _clearLogin() async {
    await _secureStorage.delete(key: 'auth_token');
    _apiClient.clearToken();
  }

  Future<bool> consumeAiQuota() async {
    final user = state.user;
    if (user == null) return false;
    if (user.aiQuota <= 0) return false;

    try {
      final result = await _userService.consumeQuota('smart_analysis');
      final newQuota = result['remaining_quota'] as int;
      state = state.copyWith(user: user.copyWith(aiQuota: newQuota));
      return true;
    } catch (e) {
      debugPrint('Consume quota error: $e');
      return false;
    }
  }

  Future<void> refreshUser() async {
    final user = state.user;
    if (user == null) return;
    try {
      final profileData = await _userService.getProfile();
      state = state.copyWith(user: User.fromApiJson(profileData));
    } catch (e) {
      debugPrint('Refresh user error: $e');
    }
  }
}
