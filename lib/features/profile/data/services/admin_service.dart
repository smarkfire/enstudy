import 'package:enstudy/core/network/api_client.dart';

class AdminService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> listUsers({int page = 1, int pageSize = 20, String? search}) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    if (search != null) {
      queryParams['search'] = search;
    }
    return await _apiClient.get('/api/admin/users?$queryParams');
  }

  Future<Map<String, dynamic>> updateQuota(String userId, int change) async {
    return await _apiClient.post('/api/admin/update-quota', {
      'user_id': userId,
      'change': change,
    });
  }
}
