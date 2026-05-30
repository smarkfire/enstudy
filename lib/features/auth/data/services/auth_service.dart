import 'package:enstudy/core/network/api_client.dart';
import 'package:enstudy/features/auth/domain/entities/user.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  Future<void> sendVerificationCode(String phone) async {
    await _apiClient.post('/api/auth/send-code', {'phone': phone});
  }

  Future<LoginResult> login(String phone, String code) async {
    final response = await _apiClient.post('/api/auth/login', {
      'phone': phone,
      'code': code,
    });
    return LoginResult.fromJson(response);
  }
}

class LoginResult {
  final String token;
  final User user;

  LoginResult({required this.token, required this.user});

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      token: json['token'],
      user: User.fromApiJson(json['user']),
    );
  }
}
