import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lookat_app/Utils/Utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/request/register_request.dart';
import '../models/response/login_response.dart';
import '../models/response/google_login_response.dart';
import '../models/response/refresh_response.dart';
import '../models/user_dto.dart';

class AuthService {
  // SharedPreferences keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';

  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Lưu token vào SharedPreference
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  Future<void> saveUser(UserDto user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<UserDto?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      return UserDto.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ============================================
  // API CALLS
  // ============================================

  Future<String> registerUser({
    required String username,
    required String email,
    required String password,
    String? avatarUrl,
  }) async {
    try {
      final request = RegisterRequest(
        username: username,
        email: email,
        password: password,
        avatarUrl: avatarUrl,
      );

      print('🔵 [AuthService] Registering user...');
      print('🔵 [AuthService] API URL: ${Utils.baseUrl + Utils.registerUrl}');
      print('🔵 [AuthService] Username: $username');
      print('🔵 [AuthService] Email: $email');
      print('🔵 [AuthService] Request body: ${jsonEncode(request.toJson())}');

      final response = await http.post(
        Uri.parse("${Utils.baseUrl + Utils.registerUrl}"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: Không thể kết nối đến server. Vui lòng kiểm tra:\n'
              '1. Backend có đang chạy không?\n'
              '2. Địa chỉ IP có đúng không? (${Utils.baseUrl + Utils.registerUrl})');
        },
      );

      print('🔵 [AuthService] Response status: ${response.statusCode}');
      print('🔵 [AuthService] Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = jsonDecode(response.body);
          return data['message'] ?? 'Đăng ký thành công!';
        } catch (e) {
          print('❌ [AuthService] Failed to parse success response: $e');
          return 'Đăng ký thành công!';
        }
      } else if (response.statusCode == 400) {
        try {
          final error = jsonDecode(response.body);

          // Xử lý ASP.NET Core validation errors
          if (error.containsKey('errors') && error['errors'] is Map) {
            final errors = error['errors'] as Map<String, dynamic>;
            final errorMessages = <String>[];

            errors.forEach((field, messages) {
              if (messages is List) {
                errorMessages.addAll(messages.map((m) => m.toString()));
              }
            });

            final message = errorMessages.isNotEmpty
                ? errorMessages.join('\n')
                : 'Dữ liệu không hợp lệ';
            print('❌ [AuthService] Validation errors: $message');
            throw Exception(message);
          }

          // Xử lý message thông thường
          final message = error['message'] ?? 'Email đã tồn tại hoặc dữ liệu không hợp lệ';
          print('❌ [AuthService] Server returned 400: $message');
          throw Exception(message);
        } catch (e) {
          if (e is Exception) rethrow;
          print('❌ [AuthService] Failed to parse error response: $e');
          throw Exception('Đăng ký thất bại: ${response.body}');
        }
      } else {
        print('❌ [AuthService] Unexpected status code: ${response.statusCode}');
        throw Exception('Đăng ký thất bại. Status code: ${response.statusCode}\nResponse: ${response.body}');
      }
    } on Exception catch (e) {
      // Nếu e đã là Exception, rethrow để giữ nguyên message
      print('❌ [AuthService] Exception during register: $e');
      rethrow;
    } catch (e) {
      // Các lỗi khác (network, timeout, etc)
      print('❌ [AuthService] Unknown error during register: $e');
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }

  /// 2️⃣ XÁC NHẬN EMAIL VỚI OTP
  Future<String> verifyOTP({
    required String email,
    required String otpCode,
  }) async {
    try {
      print('🔵 [AuthService] Verifying OTP...');
      print('🔵 [AuthService] Email: $email');
      print('🔵 [AuthService] OTP: $otpCode');

      final response = await http.post(
        Uri.parse('${Utils.baseUrl + Utils.verify_otp_url}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otpCode': otpCode,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: Không thể kết nối đến server.');
        },
      );

      print('🔵 [AuthService] Response status: ${response.statusCode}');
      print('🔵 [AuthService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          return data['message'] ?? 'Xác nhận OTP thành công!';
        } catch (e) {
          print('❌ [AuthService] Failed to parse success response: $e');
          return 'Xác nhận OTP thành công!';
        }
      } else if (response.statusCode == 400) {
        try {
          final error = jsonDecode(response.body);
          final message = error['message'] ?? 'Mã OTP không đúng hoặc đã hết hạn';
          print('❌ [AuthService] Server returned 400: $message');
          throw Exception(message);
        } catch (e) {
          if (e is Exception) rethrow;
          print('❌ [AuthService] Failed to parse error response: $e');
          throw Exception('Xác nhận OTP thất bại: ${response.body}');
        }
      } else {
        print('❌ [AuthService] Unexpected status code: ${response.statusCode}');
        throw Exception('Xác nhận OTP thất bại. Status code: ${response.statusCode}');
      }
    } on Exception catch (e) {
      print('❌ [AuthService] Exception during verify OTP: $e');
      rethrow;
    } catch (e) {
      print('❌ [AuthService] Unknown error during verify OTP: $e');
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }

  /// 3️⃣ GỬI LẠI OTP
  Future<String> resendOTP(String email) async {
    try {
      print('🔵 [AuthService] Resending OTP...');
      print('🔵 [AuthService] Email: $email');

      final response = await http.post(
        Uri.parse('${Utils.baseUrl + Utils.resend_otp_url}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: Không thể kết nối đến server.');
        },
      );

      print('🔵 [AuthService] Response status: ${response.statusCode}');
      print('🔵 [AuthService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          return data['message'] ?? 'Đã gửi lại mã OTP';
        } catch (e) {
          print('❌ [AuthService] Failed to parse success response: $e');
          return 'Đã gửi lại mã OTP';
        }
      } else if (response.statusCode == 400) {
        try {
          final error = jsonDecode(response.body);
          final message = error['message'] ?? 'Gửi lại OTP thất bại';
          print('❌ [AuthService] Server returned 400: $message');
          throw Exception(message);
        } catch (e) {
          if (e is Exception) rethrow;
          print('❌ [AuthService] Failed to parse error response: $e');
          throw Exception('Gửi lại OTP thất bại: ${response.body}');
        }
      } else {
        print('❌ [AuthService] Unexpected status code: ${response.statusCode}');
        throw Exception('Gửi lại OTP thất bại. Status code: ${response.statusCode}');
      }
    } on Exception catch (e) {
      print('❌ [AuthService] Exception during resend OTP: $e');
      rethrow;
    } catch (e) {
      print('❌ [AuthService] Unknown error during resend OTP: $e');
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }

  /// 2️⃣ XÁC NHẬN EMAIL (CŨ - GIỮ LẠI ĐỂ TƯƠNG THÍCH)
  @Deprecated('Use verifyOTP instead')
  Future<String> verifyEmail(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${Utils.baseUrl + Utils.verify_email_url}?token=$token'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Xác nhận email thành công!';
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Token không hợp lệ hoặc đã hết hạn');
      } else {
        throw Exception('Xác nhận email thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi xác nhận email: ${e.toString()}');
    }
  }

  /// 3️⃣ ĐĂNG NHẬP BẰNG EMAIL/PASSWORD
  Future<LoginResponse> login(String email, String password) async {
    try {
      print('🔵 [AuthService] Logging in...');
      print('🔵 [AuthService] API URL: ${Utils.baseUrl + Utils.loginUrl}');
      print('🔵 [AuthService] Email: $email');

      final requestBody = {
        'email': email,
        'password': password,
      };
      print('🔵 [AuthService] Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('${Utils.baseUrl + Utils.loginUrl}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: Không thể kết nối đến server. Vui lòng kiểm tra:\n'
              '1. Backend có đang chạy không?\n'
              '2. Địa chỉ IP có đúng không? (${Utils.baseUrl})');
        },
      );

      print('🔵 [AuthService] Response status: ${response.statusCode}');
      print('🔵 [AuthService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final loginResponse = LoginResponse.fromJson(data);

        // Lưu tokens và user info
        await saveTokens(loginResponse.accessToken, loginResponse.refreshToken);
        await saveUser(loginResponse.user);

        print('✅ [AuthService] Login successful! User: ${loginResponse.user.email}');
        return loginResponse;
      } else if (response.statusCode == 400) {
        try {
          final error = jsonDecode(response.body);
          final message = error['message'] ?? 'Đăng nhập thất bại';
          print('❌ [AuthService] Server returned 400: $message');

          if (message.contains('Google')) {
            throw Exception('Tài khoản này được đăng ký qua Google. Vui lòng đăng nhập bằng Google.');
          } else if (message.contains('verify') || message.contains('xác nhận') || message.contains('not verified')) {
            throw Exception('Tài khoản chưa được xác minh. Vui lòng kiểm tra email và nhập mã OTP để xác nhận tài khoản.');
          } else {
            throw Exception(message);
          }
        } catch (e) {
          if (e is Exception) rethrow;
          print('❌ [AuthService] Failed to parse error response: $e');
          throw Exception('Đăng nhập thất bại: ${response.body}');
        }
      } else if (response.statusCode == 401) {
        try {
          final error = jsonDecode(response.body);
          final message = error['message'] ?? 'Email hoặc mật khẩu không đúng';
          print('❌ [AuthService] Server returned 401: $message');
          throw Exception(message);
        } catch (e) {
          if (e is Exception) rethrow;
          print('❌ [AuthService] Failed to parse error response: $e');
          throw Exception('Email hoặc mật khẩu không đúng');
        }
      } else {
        print('❌ [AuthService] Unexpected status code: ${response.statusCode}');
        throw Exception('Đăng nhập thất bại. Status code: ${response.statusCode}\nResponse: ${response.body}');
      }
    } on Exception catch (e) {
      print('❌ [AuthService] Exception during login: $e');
      rethrow;
    } catch (e) {
      print('❌ [AuthService] Unknown error during login: $e');
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }

  /// 4️⃣ ĐĂNG NHẬP BẰNG GOOGLE
  Future<GoogleLoginResponse> loginWithGoogle(String idToken) async {
    try {
      // Debug log
      print('🔵 [AuthService] Sending Google ID Token to backend...');
      print('🔵 [AuthService] Token length: ${idToken.length}');
      print('🔵 [AuthService] API URL: ${Utils.baseUrl + Utils.google_Url}');

      final response = await http.post(
        Uri.parse('${Utils.baseUrl + Utils.google_Url}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': idToken,
        }),
      );

      print('🔵 [AuthService] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final googleResponse = GoogleLoginResponse.fromJson(data);

        print('✅ [AuthService] Google login successful!');
        print('✅ [AuthService] User: ${googleResponse.user.email}');

        // Lưu tokens và user info
        await saveTokens(googleResponse.accessToken, googleResponse.refreshToken);
        await saveUser(googleResponse.user);

        return googleResponse;
      } else if (response.statusCode == 400 || response.statusCode == 401) {
        print('❌ [AuthService] Error ${response.statusCode}: ${response.body}');
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Đăng nhập Google thất bại');
      } else {
        print('❌ [AuthService] Unexpected error: ${response.statusCode}');
        throw Exception('Đăng nhập Google thất bại. Vui lòng thử lại sau.');
      }
    } catch (e) {
      print('❌ [AuthService] Exception: $e');
      if (e is Exception) rethrow;
      throw Exception('Lỗi kết nối Google: ${e.toString()}');
    }
  }

  /// 5️⃣ QUÊN MẬT KHẨU
  Future<String> requestForgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${Utils.baseUrl + Utils.forgotPasswordUrl}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Email đặt lại mật khẩu đã được gửi.';
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        final message = error['message'] ?? 'Không thể gửi email đặt lại mật khẩu';

        if (message.contains('Google')) {
          throw Exception('Tài khoản Google không thể đặt lại mật khẩu.');
        } else {
          throw Exception(message);
        }
      } else if (response.statusCode == 404) {
        throw Exception('Email không tồn tại trong hệ thống.');
      } else {
        throw Exception('Gửi email thất bại. Vui lòng thử lại sau.');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }

  /// 6️⃣ ĐẶT LẠI MẬT KHẨU
  Future<String> resetPassword(String token, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('${Utils.baseUrl + Utils.reset_password_url}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Đặt lại mật khẩu thành công.';
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Token không hợp lệ hoặc đã hết hạn');
      } else {
        throw Exception('Đặt lại mật khẩu thất bại. Vui lòng thử lại sau.');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }

  /// 7️⃣ LÀM MỚI TOKEN
  Future<RefreshResponse> refreshToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse('${Utils.baseUrl + Utils.refresh_token_url}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'refreshToken': refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final refreshResponse = RefreshResponse.fromJson(data);

        // Lưu tokens mới
        await saveTokens(refreshResponse.accessToken, refreshResponse.refreshToken);

        return refreshResponse;
      } else if (response.statusCode == 400 || response.statusCode == 401) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Refresh token không hợp lệ');
      } else {
        throw Exception('Làm mới token thất bại');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Lỗi làm mới token: ${e.toString()}');
    }
  }

  /// 8️⃣ ĐĂNG XUẤT
  Future<void> logout(String accessToken) async {
    try {
      final response = await http.post(
        Uri.parse('${Utils.baseUrl + Utils.logout_url}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      // Xóa tokens local dù API có thành công hay không
      await clearTokens();

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        // Token đã hết hạn, vẫn coi như logout thành công
        return;
      } else {
        // Vẫn coi như logout thành công vì đã xóa local tokens
        return;
      }
    } catch (e) {
      // Xóa tokens local dù có lỗi
      await clearTokens();
      throw Exception('Lỗi đăng xuất: ${e.toString()}');
    }
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Tạo header với Authorization Bearer token
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Kiểm tra và tự động refresh token nếu cần
  Future<bool> ensureValidToken() async {
    final accessToken = await getAccessToken();
    if (accessToken == null) return false;

    // TODO: Implement JWT decode để check expiry
    // Nếu token sắp hết hạn, gọi refreshToken()

    return true;
  }
}

