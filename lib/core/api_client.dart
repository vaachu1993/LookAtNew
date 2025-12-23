import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lookat_app/Utils/Utils.dart';
import 'auth_storage.dart';
import 'api_interceptor.dart';
import '../models/user.dart';

class ApiClient {
  final AuthStorage authStorage = AuthStorage();
  final ApiInterceptor _interceptor = ApiInterceptor();

  // Singleton pattern
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  // ==================== Helper Methods ====================

  /// Build headers with Bearer token if logged in
  Future<Map<String, String>> _buildHeaders({bool requireAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requireAuth) {
      final token = await authStorage.getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// Parse JSON response safely
  Map<String, dynamic> _parseJsonResponse(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      return {'message': body};
    }
  }

  /// Handle API response
  Future<ApiResponse<T>> _handleResponse<T>(
    http.Response response, {
    T Function(Map<String, dynamic>)? parser,
  }) async {
    try {
      final body = _parseJsonResponse(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Success
        final data = parser != null ? parser(body) : body as T;
        return ApiResponse<T>.success(
          data: data,
          statusCode: response.statusCode,
          message: body['message'] as String?,
        );
      } else if (response.statusCode == 401) {
        // Unauthorized - try refresh token
        final refreshed = await _refreshToken();
        if (refreshed) {
          // Refresh successful, should retry
          return ApiResponse<T>.error(
            message: 'Token refreshed. Please retry.',
            statusCode: 401,
            error: 'RETRY',
          );
        } else {
          // Refresh failed
          await authStorage.deleteTokens();
          return ApiResponse<T>.error(
            message: 'Session expired. Please login again.',
            statusCode: 401,
          );
        }
      } else {
        // Other errors
        final message = body['message'] as String? ?? 
                       'Request failed with status ${response.statusCode}';
        return ApiResponse<T>.error(
          message: message,
          statusCode: response.statusCode,
          error: body,
        );
      }
    } catch (e) {
      return ApiResponse<T>.error(
        message: 'Error parsing response: ${e.toString()}',
        statusCode: 0,
        error: e,
      );
    }
  }

  // ==================== Token Management ====================

  /// Refresh access token using refresh token
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await authStorage.getRefreshToken();
      if (refreshToken == null) {
        return false;
      }

      final headers = await _buildHeaders(requireAuth: false);
      final response = await http.post(
        Uri.parse('${Utils.baseUrl + Utils.refresh_token_url}'),
        headers: headers,
        body: jsonEncode({'refreshToken': refreshToken}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = _parseJsonResponse(response.body);
        final newAccessToken = body['accessToken'] as String?;
        final newRefreshToken = body['refreshToken'] as String?;

        if (newAccessToken != null) {
          await authStorage.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ==================== Authentication APIs ====================

  /// Login with email and password
  /// POST /Auth/login
  Future<ApiResponse<User>> login({
    required String email,
    required String password,
  }) async {
    try {
      final headers = await _buildHeaders(requireAuth: false);
      final response = await http.post(
        Uri.parse('${Utils.baseUrl + Utils.loginUrl}'),
        headers: headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = _parseJsonResponse(response.body);
        
        // Save tokens
        final accessToken = body['accessToken'] as String?;
        final refreshToken = body['refreshToken'] as String?;
        
        if (accessToken != null) {
          await authStorage.saveTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
          );

          // Parse user data
          final userData = body['user'] as Map<String, dynamic>?;
          if (userData != null) {
            await authStorage.saveUserData(userData);
            final user = User.fromJson(userData);
            return ApiResponse<User>.success(
              data: user,
              statusCode: 200,
              message: 'Login successful',
            );
          }
        }

        return ApiResponse<User>.error(
          message: 'No token in response',
          statusCode: 200,
        );
      }

      final body = _parseJsonResponse(response.body);
      final message = body['message'] as String? ?? 'Login failed';
      
      return ApiResponse<User>.error(
        message: message,
        statusCode: response.statusCode,
        error: body,
      );
    } on http.ClientException catch (e) {
      return ApiResponse<User>.error(
        message: 'Network error: ${e.message}',
        statusCode: 0,
        error: e,
      );
    } catch (e) {
      return ApiResponse<User>.error(
        message: 'Login error: ${e.toString()}',
        statusCode: 0,
        error: e,
      );
    }
  }

  /// Register new account
  /// POST /Auth/register
  Future<ApiResponse<Map<String, dynamic>>> register({
    required String email,
    required String username,
    required String password,
  }) async {
    try {
      final headers = await _buildHeaders(requireAuth: false);
      final response = await http.post(
        Uri.parse('${Utils.baseUrl + Utils.registerUrl}'),
        headers: headers,
        body: jsonEncode({
          'email': email,
          'username': username,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = _parseJsonResponse(response.body);
        return ApiResponse<Map<String, dynamic>>.success(
          data: body,
          statusCode: response.statusCode,
          message: 'Registration successful',
        );
      }

      final body = _parseJsonResponse(response.body);
      final message = body['message'] as String? ?? 'Registration failed';
      
      return ApiResponse<Map<String, dynamic>>.error(
        message: message,
        statusCode: response.statusCode,
        error: body,
      );
    } on http.ClientException catch (e) {
      return ApiResponse<Map<String, dynamic>>.error(
        message: 'Network error: ${e.message}',
        statusCode: 0,
        error: e,
      );
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>.error(
        message: 'Registration error: ${e.toString()}',
        statusCode: 0,
        error: e,
      );
    }
  }

  /// Google OAuth login
  /// POST /Auth/google
  Future<ApiResponse<User>> loginWithGoogle(String idToken) async {
    try {
      final headers = await _buildHeaders(requireAuth: false);
      final response = await http.post(
        Uri.parse('${Utils.baseUrl + Utils.google_Url}'),
        headers: headers,
        body: jsonEncode({'idToken': idToken}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = _parseJsonResponse(response.body);
        final accessToken = body['accessToken'] as String?;
        final refreshToken = body['refreshToken'] as String?;
        
        if (accessToken != null) {
          await authStorage.saveTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
          );

          final userData = body['user'] as Map<String, dynamic>?;
          if (userData != null) {
            await authStorage.saveUserData(userData);
            final user = User.fromJson(userData);
            return ApiResponse<User>.success(
              data: user,
              statusCode: 200,
              message: 'Google login successful',
            );
          }
        }

        return ApiResponse<User>.error(
          message: 'No token in response',
          statusCode: 200,
        );
      }

      final body = _parseJsonResponse(response.body);
      final message = body['message'] as String? ?? 'Google login failed';
      
      return ApiResponse<User>.error(
        message: message,
        statusCode: response.statusCode,
      );
    } on http.ClientException catch (e) {
      return ApiResponse<User>.error(
        message: 'Network error: ${e.message}',
        statusCode: 0,
        error: e,
      );
    } catch (e) {
      return ApiResponse<User>.error(
        message: 'Google login error: ${e.toString()}',
        statusCode: 0,
        error: e,
      );
    }
  }

  /// Request password reset email
  /// POST /Auth/forgot-password
  Future<ApiResponse<Map<String, dynamic>>> requestPasswordReset(
    String email,
  ) async {
    try {
      final headers = await _buildHeaders(requireAuth: false);
      final response = await http.post(
        Uri.parse('${Utils.baseUrl + Utils.forgotPasswordUrl}'),
        headers: headers,
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = _parseJsonResponse(response.body);
        return ApiResponse<Map<String, dynamic>>.success(
          data: body,
          statusCode: response.statusCode,
          message: 'Password reset email sent',
        );
      }

      final body = _parseJsonResponse(response.body);
      final message = body['message'] as String? ?? 'Request failed';
      
      return ApiResponse<Map<String, dynamic>>.error(
        message: message,
        statusCode: response.statusCode,
      );
    } on http.ClientException catch (e) {
      return ApiResponse<Map<String, dynamic>>.error(
        message: 'Network error: ${e.message}',
        statusCode: 0,
        error: e,
      );
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>.error(
        message: 'Error: ${e.toString()}',
        statusCode: 0,
        error: e,
      );
    }
  }

  /// Reset password with token
  /// POST /Auth/reset-password
  Future<ApiResponse<Map<String, dynamic>>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final headers = await _buildHeaders(requireAuth: false);
      final response = await http.post(
        Uri.parse('${Utils.baseUrl + Utils.reset_password_url}'),
        headers: headers,
        body: jsonEncode({
          'token': token,
          'newPassword': newPassword,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = _parseJsonResponse(response.body);
        return ApiResponse<Map<String, dynamic>>.success(
          data: body,
          statusCode: response.statusCode,
          message: 'Password reset successful',
        );
      }

      final body = _parseJsonResponse(response.body);
      final message = body['message'] as String? ?? 'Reset failed';
      
      return ApiResponse<Map<String, dynamic>>.error(
        message: message,
        statusCode: response.statusCode,
      );
    } on http.ClientException catch (e) {
      return ApiResponse<Map<String, dynamic>>.error(
        message: 'Network error: ${e.message}',
        statusCode: 0,
        error: e,
      );
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>.error(
        message: 'Error: ${e.toString()}',
        statusCode: 0,
        error: e,
      );
    }
  }

  /// Test if email exists
  /// GET /Auth/test-email?email=...
  Future<ApiResponse<bool>> testEmailExists(String email) async {
    try {
      final headers = await _buildHeaders(requireAuth: false);
      final response = await http.get(
        Uri.parse('${Utils.baseUrl}/Auth/test-email?email=${Uri.encodeComponent(email)}'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = _parseJsonResponse(response.body);
        final exists = body['exists'] as bool? ?? false;
        return ApiResponse<bool>.success(
          data: exists,
          statusCode: 200,
        );
      }

      return ApiResponse<bool>.error(
        message: 'Failed to check email',
        statusCode: response.statusCode,
      );
    } on http.ClientException catch (e) {
      return ApiResponse<bool>.error(
        message: 'Network error: ${e.message}',
        statusCode: 0,
        error: e,
      );
    } catch (e) {
      return ApiResponse<bool>.error(
        message: 'Error: ${e.toString()}',
        statusCode: 0,
        error: e,
      );
    }
  }

  /// Logout
  /// POST /Auth/logout
  Future<ApiResponse<Map<String, dynamic>>> logout() async {
    try {
      final headers = await _buildHeaders(requireAuth: true);
      final response = await http.post(
        Uri.parse('${Utils.baseUrl + Utils.logout_url}'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      // Clear tokens regardless of response
      await authStorage.deleteTokens();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = _parseJsonResponse(response.body);
        return ApiResponse<Map<String, dynamic>>.success(
          data: body,
          statusCode: response.statusCode,
          message: 'Logout successful',
        );
      }

      return ApiResponse<Map<String, dynamic>>.success(
        data: {},
        statusCode: 200,
        message: 'Logout successful',
      );
    } catch (e) {
      // Still clear tokens on error
      await authStorage.deleteTokens();
      return ApiResponse<Map<String, dynamic>>.success(
        data: {},
        statusCode: 200,
        message: 'Logout successful',
      );
    }
  }

  // ==================== User APIs ====================

  /// Get current user info
  /// GET /User/me
  Future<ApiResponse<User>> getCurrentUser() async {
    try {
      final headers = await _buildHeaders(requireAuth: true);
      final response = await http.get(
        Uri.parse('${Utils.baseUrl}/User/me'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      // Handle with interceptor logic for 401
      if (response.statusCode == 401) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          // Retry with new token
          return getCurrentUser();
        } else {
          await authStorage.deleteTokens();
          return ApiResponse<User>.error(
            message: 'Session expired',
            statusCode: 401,
          );
        }
      }

      if (response.statusCode == 200) {
        final body = _parseJsonResponse(response.body);
        final user = User.fromJson(body);
        await authStorage.saveUserData(body);
        return ApiResponse<User>.success(
          data: user,
          statusCode: 200,
        );
      }

      final body = _parseJsonResponse(response.body);
      final message = body['message'] as String? ?? 'Failed to get user';
      
      return ApiResponse<User>.error(
        message: message,
        statusCode: response.statusCode,
      );
    } on http.ClientException catch (e) {
      return ApiResponse<User>.error(
        message: 'Network error: ${e.message}',
        statusCode: 0,
        error: e,
      );
    } catch (e) {
      return ApiResponse<User>.error(
        message: 'Error: ${e.toString()}',
        statusCode: 0,
        error: e,
      );
    }
  }

  /// Update user info
  /// PUT /User/update
  Future<ApiResponse<User>> updateUser({
    String? username,
    String? avatarUrl,
  }) async {
    try {
      // Lấy thông tin user hiện tại để preserve các field không thay đổi
      final currentUserResponse = await getCurrentUser();
      final currentUser = currentUserResponse.data;

      final body = <String, dynamic>{};

      // Nếu update username, giữ nguyên avatarUrl cũ
      if (username != null) {
        body['username'] = username;
        // Preserve avatarUrl nếu có
        if (currentUser?.avatarUrl != null && currentUser!.avatarUrl!.isNotEmpty) {
          body['avatarUrl'] = currentUser.avatarUrl;
        }
      }

      // Nếu update avatarUrl, giữ nguyên username cũ
      if (avatarUrl != null) {
        body['avatarUrl'] = avatarUrl;
        // Preserve username nếu có
        if (currentUser?.username != null && currentUser!.username.isNotEmpty) {
          body['username'] = currentUser.username;
        }
      }

      final headers = await _buildHeaders(requireAuth: true);
      final response = await http.put(
        Uri.parse('${Utils.baseUrl}/User/update'),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      // Handle with interceptor logic for 401
      if (response.statusCode == 401) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          // Retry with new token
          return updateUser(username: username, avatarUrl: avatarUrl);
        } else {
          await authStorage.deleteTokens();
          return ApiResponse<User>.error(
            message: 'Session expired',
            statusCode: 401,
          );
        }
      }

      if (response.statusCode == 200) {
        final responseBody = _parseJsonResponse(response.body);
        final user = User.fromJson(responseBody);
        await authStorage.saveUserData(responseBody);
        return ApiResponse<User>.success(
          data: user,
          statusCode: 200,
          message: 'Update successful',
        );
      }

      final responseBody = _parseJsonResponse(response.body);
      final message = responseBody['message'] as String? ?? 'Update failed';

      return ApiResponse<User>.error(
        message: message,
        statusCode: response.statusCode,
      );
    } on http.ClientException catch (e) {
      return ApiResponse<User>.error(
        message: 'Network error: ${e.message}',
        statusCode: 0,
        error: e,
      );
    } catch (e) {
      return ApiResponse<User>.error(
        message: 'Error: ${e.toString()}',
        statusCode: 0,
        error: e,
      );
    }
  }

  /// Upload avatar image
  /// POST /User/upload-avatar
  /// Returns the new avatar URL
  Future<ApiResponse<String>> uploadAvatar(String filePath) async {
    try {
      final token = await authStorage.getAccessToken();
      if (token == null) {
        return ApiResponse<String>.error(
          message: 'Not authenticated',
          statusCode: 401,
        );
      }

      final uri = Uri.parse('${Utils.baseUrl}/User/upload-avatar');
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add file
      final file = await http.MultipartFile.fromPath('avatar', filePath);
      request.files.add(file);

      // Send request
      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      // Handle 401
      if (response.statusCode == 401) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          return uploadAvatar(filePath);
        } else {
          await authStorage.deleteTokens();
          return ApiResponse<String>.error(
            message: 'Session expired',
            statusCode: 401,
          );
        }
      }

      if (response.statusCode == 200) {
        final responseBody = _parseJsonResponse(response.body);
        final avatarUrl = responseBody['avatarUrl'] as String? ?? responseBody['url'] as String?;

        if (avatarUrl == null) {
          return ApiResponse<String>.error(
            message: 'Avatar URL not found in response',
            statusCode: 500,
          );
        }

        return ApiResponse<String>.success(
          data: avatarUrl,
          statusCode: 200,
          message: 'Upload successful',
        );
      }

      final responseBody = _parseJsonResponse(response.body);
      final message = responseBody['message'] as String? ?? 'Upload failed';

      return ApiResponse<String>.error(
        message: message,
        statusCode: response.statusCode,
      );
    } on http.ClientException catch (e) {
      return ApiResponse<String>.error(
        message: 'Network error: ${e.message}',
        statusCode: 0,
        error: e,
      );
    } catch (e) {
      return ApiResponse<String>.error(
        message: 'Error: ${e.toString()}',
        statusCode: 0,
        error: e,
      );
    }
  }

  /// Upload avatar image (Mock version for testing)
  /// POST /User/upload-avatar
  /// Returns a mock avatar URL for testing UI flow
  Future<ApiResponse<String>> uploadAvatarMock(String filePath) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      // Return mock URL for testing
      const mockAvatarUrl = 'https://picsum.photos/200/200'; // Random 200x200 image

      return ApiResponse<String>.success(
        data: mockAvatarUrl,
        statusCode: 200,
        message: 'Mock upload successful',
      );
    } catch (e) {
      return ApiResponse<String>.error(
        message: 'Mock upload failed',
        statusCode: 0,
        error: e,
      );
    }
  }
}
