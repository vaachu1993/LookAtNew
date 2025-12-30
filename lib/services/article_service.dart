import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lookat_app/Utils/Utils.dart';
import '../core/auth_storage.dart';
import '../models/article_model.dart';
import 'rss_service.dart';

/// Service để lấy tất cả bài viết từ database
/// Sử dụng endpoint GET /api/Articles thay vì /api/Feed
class ArticleService {
  final AuthStorage _authStorage = AuthStorage();
  final RssService _rssService = RssService();

  // Singleton pattern
  static final ArticleService _instance = ArticleService._internal();
  factory ArticleService() => _instance;
  ArticleService._internal();

  /// Get tất cả articles từ database
  /// GET /api/Articles
  ///
  /// Returns: List of all articles (không phụ thuộc user preferences)
  Future<ArticleResponse> getAllArticles() async {
    try {
      // Get token (vẫn cần cho authentication)
      final token = await _authStorage.getAccessToken();

      if (token == null) {
        return ArticleResponse.error('No authentication token found');
      }

      // Build headers
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // Build URL
      String url = '${Utils.baseUrl}/Articles';

      // Make request
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      // Handle response
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
        final articles = jsonList
            .map((json) => ArticleModel.fromJson(json as Map<String, dynamic>))
            .toList();

        return ArticleResponse.success(articles);
      } else if (response.statusCode == 401) {
        return ArticleResponse.error('Authentication failed. Please login again.');
      } else {
        return ArticleResponse.error(
          'Failed to load articles. Status: ${response.statusCode}'
        );
      }
    } catch (e) {
      return ArticleResponse.error('Error loading articles: ${e.toString()}');
    }
  }

  /// Get articles by category
  /// GET /api/Articles/category/{name}
  Future<ArticleResponse> getArticlesByCategory(String categoryName) async {
    try {
      // Get token
      final token = await _authStorage.getAccessToken();

      if (token == null) {
        return ArticleResponse.error('No authentication token found');
      }

      // Build headers
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // Build URL
      String url = '${Utils.baseUrl}/Articles/category/$categoryName';

      // Make request
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      // Handle response
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
        final articles = jsonList
            .map((json) => ArticleModel.fromJson(json as Map<String, dynamic>))
            .toList();

        return ArticleResponse.success(articles);
      } else if (response.statusCode == 401) {
        return ArticleResponse.error('Authentication failed. Please login again.');
      } else {
        return ArticleResponse.error(
          'Failed to load articles. Status: ${response.statusCode}'
        );
      }
    } catch (e) {
      return ArticleResponse.error('Error loading articles: ${e.toString()}');
    }
  }

  /// Get article detail by ID
  /// GET /api/Articles/{id}
  Future<ArticleDetailResponse> getArticleById(String id) async {
    try {
      // Get token
      final token = await _authStorage.getAccessToken();

      if (token == null) {
        return ArticleDetailResponse.error('No authentication token found');
      }

      // Build headers
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // Build URL
      String url = '${Utils.baseUrl}/Articles/$id';

      // Make request
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      // Handle response
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final article = ArticleModel.fromJson(json);

        return ArticleDetailResponse.success(article);
      } else if (response.statusCode == 401) {
        return ArticleDetailResponse.error('Authentication failed. Please login again.');
      } else if (response.statusCode == 404) {
        return ArticleDetailResponse.error('Article not found');
      } else {
        return ArticleDetailResponse.error(
          'Failed to load article. Status: ${response.statusCode}'
        );
      }
    } catch (e) {
      return ArticleDetailResponse.error('Error loading article: ${e.toString()}');
    }
  }

  /// Fetch RSS mới từ nguồn rồi lấy tất cả articles
  ///
  /// Flow:
  /// 1. POST /api/Rss/fetch (fetch RSS mới)
  /// 2. GET /api/Articles (lấy tất cả bài viết)
  ///
  /// Returns: ArticleResponseWithRssFetch
  Future<ArticleResponseWithRssFetch> fetchRssAndGetArticles({
    String? category,
  }) async {
    try {
      // Step 1: Fetch RSS từ nguồn
      final rssResponse = await _rssService.fetchRss(category: category);

      if (!rssResponse.isSuccess) {
        // RSS fetch failed, try to get articles anyway
        final articleResponse = category != null && category != 'all'
            ? await getArticlesByCategory(category)
            : await getAllArticles();

        return ArticleResponseWithRssFetch(
          articleResponse: articleResponse,
          rssFetchSuccess: false,
          rssFetchError: rssResponse.error,
          articlesCount: 0,
        );
      }

      // Step 2: Get articles từ database (sau khi RSS đã được crawl)
      final articleResponse = category != null && category != 'all'
          ? await getArticlesByCategory(category)
          : await getAllArticles();

      return ArticleResponseWithRssFetch(
        articleResponse: articleResponse,
        rssFetchSuccess: true,
        rssFetchMessage: rssResponse.message,
        articlesCount: rssResponse.articlesCount ?? 0,
      );
    } catch (e) {
      // Error, return articles if available
      final articleResponse = category != null && category != 'all'
          ? await getArticlesByCategory(category)
          : await getAllArticles();

      return ArticleResponseWithRssFetch(
        articleResponse: articleResponse,
        rssFetchSuccess: false,
        rssFetchError: 'Error: ${e.toString()}',
        articlesCount: 0,
      );
    }
  }
}

/// Response wrapper for Articles API
class ArticleResponse {
  final List<ArticleModel>? articles;
  final String? error;
  final bool isSuccess;

  ArticleResponse._({
    this.articles,
    this.error,
    required this.isSuccess,
  });

  factory ArticleResponse.success(List<ArticleModel> articles) {
    return ArticleResponse._(
      articles: articles,
      isSuccess: true,
    );
  }

  factory ArticleResponse.error(String error) {
    return ArticleResponse._(
      error: error,
      isSuccess: false,
    );
  }
}

/// Response wrapper for single Article
class ArticleDetailResponse {
  final ArticleModel? article;
  final String? error;
  final bool isSuccess;

  ArticleDetailResponse._({
    this.article,
    this.error,
    required this.isSuccess,
  });

  factory ArticleDetailResponse.success(ArticleModel article) {
    return ArticleDetailResponse._(
      article: article,
      isSuccess: true,
    );
  }

  factory ArticleDetailResponse.error(String error) {
    return ArticleDetailResponse._(
      error: error,
      isSuccess: false,
    );
  }
}

/// Combined response: RSS Fetch + Get Articles
class ArticleResponseWithRssFetch {
  final ArticleResponse articleResponse;
  final bool rssFetchSuccess;
  final String? rssFetchMessage;
  final String? rssFetchError;
  final int articlesCount; // Số lượng articles được fetch từ RSS

  ArticleResponseWithRssFetch({
    required this.articleResponse,
    required this.rssFetchSuccess,
    this.rssFetchMessage,
    this.rssFetchError,
    required this.articlesCount,
  });
}

