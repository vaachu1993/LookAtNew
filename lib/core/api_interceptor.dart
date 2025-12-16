import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_storage.dart';

/// API Response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int statusCode;
  final dynamic error;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    required this.statusCode,
    this.error,
  });

  factory ApiResponse.success({
    required T data,
    required int statusCode,
    String? message,
  }) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
      statusCode: statusCode,
      error: null,
    );
  }

  factory ApiResponse.error({
    required String message,
    required int statusCode,
    dynamic error,
  }) {
    return ApiResponse(
      success: false,
      data: null,
      message: message,
      statusCode: statusCode,
      error: error,
    );
  }

  @override
  String toString() {
    return 'ApiResponse(success: $success, statusCode: $statusCode, message: $message)';
  }
}

/// HTTP Interceptor with auto-retry and token refresh
class ApiInterceptor {
  final AuthStorage _authStorage = AuthStorage();
  bool _isRefreshing = false;

  /// Execute request with retry logic
  Future<http.Response> request(
    Future<http.Response> Function() requestFn, {
    int maxRetries = 1,
  }) async {
    try {
      final response = await requestFn();

      // Unauthorized - token expired
      if (response.statusCode == 401) {
        if (_isRefreshing) {
          // Already refreshing, wait a bit
          await Future.delayed(const Duration(milliseconds: 500));
          return await requestFn();
        }

        // Try to refresh token
        _isRefreshing = true;
        try {
          final refreshed = await _refreshAccessToken();
          _isRefreshing = false;

          if (refreshed) {
            // Retry original request
            return await requestFn();
          } else {
            // Refresh failed - need to logout
            await _authStorage.deleteTokens();
            throw Exception('Session expired. Please login again.');
          }
        } catch (e) {
          _isRefreshing = false;
          await _authStorage.deleteTokens();
          rethrow;
        }
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Refresh access token using refresh token
  Future<bool> _refreshAccessToken() async {
    try {
      final refreshToken = await _authStorage.getRefreshToken();
      if (refreshToken == null) {
        return false;
      }

      // This will be called from ApiClient
      // For now, return false to indicate refresh failed
      return false;
    } catch (e) {
      return false;
    }
  }
}

