import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/auth_storage.dart';
import '../models/article_model.dart';

class FeedService {
  // Base URL for ASP.NET Core backend
  static const String _baseUrl = 'http://10.0.2.2:5201/api';

  final AuthStorage _authStorage = AuthStorage();

  // Singleton pattern
  static final FeedService _instance = FeedService._internal();
  factory FeedService() => _instance;
  FeedService._internal();

  /// Get feed articles from backend
  /// GET /api/feed
  Future<FeedResponse> getFeed() async {
    try {
      // Get token
      final token = await _authStorage.getAccessToken();

      if (token == null) {
        return FeedResponse.error('No authentication token found');
      }

      // Build headers
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // Make request
      final response = await http.get(
        Uri.parse('$_baseUrl/feed'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      // Handle response
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
        final articles = jsonList
            .map((json) => ArticleModel.fromJson(json as Map<String, dynamic>))
            .toList();

        return FeedResponse.success(articles);
      } else if (response.statusCode == 401) {
        return FeedResponse.error('Authentication failed. Please login again.');
      } else {
        return FeedResponse.error(
          'Failed to load feed. Status: ${response.statusCode}'
        );
      }
    } catch (e) {
      return FeedResponse.error('Error loading feed: ${e.toString()}');
    }
  }

  /// Refresh feed (same as getFeed but with different timeout)
  Future<FeedResponse> refreshFeed() async {
    return getFeed();
  }
}

/// Response wrapper for Feed API
class FeedResponse {
  final List<ArticleModel>? articles;
  final String? error;
  final bool isSuccess;

  FeedResponse._({
    this.articles,
    this.error,
    required this.isSuccess,
  });

  factory FeedResponse.success(List<ArticleModel> articles) {
    return FeedResponse._(
      articles: articles,
      isSuccess: true,
    );
  }

  factory FeedResponse.error(String error) {
    return FeedResponse._(
      error: error,
      isSuccess: false,
    );
  }
}

