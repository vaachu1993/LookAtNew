import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lookat_app/Utils/Utils.dart';
import '../core/auth_storage.dart';

/// Service để fetch RSS mới từ nguồn
/// Gọi backend để crawl RSS và lưu vào database
class RssService {
  final AuthStorage _authStorage = AuthStorage();

  // Singleton pattern
  static final RssService _instance = RssService._internal();
  factory RssService() => _instance;
  RssService._internal();

  /// Fetch RSS mới từ nguồn
  /// POST /api/Rss/fetch
  ///
  /// [category] - Category để fetch (optional)
  /// Returns: RssFetchResponse
  Future<RssFetchResponse> fetchRss({String? category}) async {
    try {
      // Get token
      final token = await _authStorage.getAccessToken();

      if (token == null) {
        return RssFetchResponse.error('No authentication token found');
      }

      // Build headers
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // Build URL
      String url = '${Utils.baseUrl + Utils.rssFetchUrl}';
      if (category != null && category != 'all') {
        url += '?category=$category';
      }

      // Make request
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 30)); // Longer timeout for RSS fetch

      // Handle response
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final message = data['message'] as String? ?? 'RSS fetched successfully';
        final count = data['count'] as int? ?? 0;

        return RssFetchResponse.success(
          message: message,
          articlesCount: count,
        );
      } else if (response.statusCode == 401) {
        return RssFetchResponse.error('Authentication failed. Please login again.');
      } else {
        final data = jsonDecode(response.body);
        final message = data['message'] as String? ?? 'Failed to fetch RSS';
        return RssFetchResponse.error(message);
      }
    } catch (e) {
      return RssFetchResponse.error('Error fetching RSS: ${e.toString()}');
    }
  }

  /// Fetch RSS cho tất cả categories
  Future<RssFetchResponse> fetchAllRss() async {
    return fetchRss(category: 'all');
  }
}

/// Response wrapper for RSS Fetch API
class RssFetchResponse {
  final String? message;
  final int? articlesCount;
  final String? error;
  final bool isSuccess;

  RssFetchResponse._({
    this.message,
    this.articlesCount,
    this.error,
    required this.isSuccess,
  });

  factory RssFetchResponse.success({
    String? message,
    int? articlesCount,
  }) {
    return RssFetchResponse._(
      message: message,
      articlesCount: articlesCount,
      isSuccess: true,
    );
  }

  factory RssFetchResponse.error(String error) {
    return RssFetchResponse._(
      error: error,
      isSuccess: false,
    );
  }
}

