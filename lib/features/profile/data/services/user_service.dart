import 'package:enstudy/core/network/api_client.dart';

class UserService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getProfile() async {
    return await _apiClient.get('/api/user/profile');
  }

  Future<Map<String, dynamic>> consumeQuota(String reason) async {
    return await _apiClient.post('/api/user/consume-quota', {'reason': reason});
  }
}
