import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lookat_app/Utils/Utils.dart';
import '../core/auth_storage.dart';
import '../models/article_model.dart';
import 'feed_cache_service.dart';
import 'rss_service.dart';

class FeedService {
  final AuthStorage _authStorage = AuthStorage();
  final FeedCacheService _cacheService = FeedCacheService();
  final RssService _rssService = RssService();

  // Singleton pattern
  static final FeedService _instance = FeedService._internal();
  factory FeedService() => _instance;
  FeedService._internal();

  /// Get feed articles with smart caching
  ///
  /// [category] - Category để filter (hoặc 'all' cho tất cả)
  /// [forceRefresh] - true = luôn fetch từ API, false = dùng cache nếu có
  ///
  /// Logic:
  /// - forceRefresh = true → fetch API
  /// - forceRefresh = false:
  ///   - Nếu shouldFetch = true → fetch API
  ///   - Nếu shouldFetch = false → dùng cache
  Future<FeedResponse> getFeed({
    String category = 'all',
    bool forceRefresh = false,
  }) async {
    try {
      // Pull-to-refresh hoặc cold start → luôn fetch
      if (forceRefresh) {
        return await _fetchFromApi(category);
      }

      // Kiểm tra có nên fetch không
      final shouldFetch = await _cacheService.shouldFetch(category);

      if (shouldFetch) {
        // Stale hoặc chưa có cache → fetch
        return await _fetchFromApi(category);
      } else {
        // Cache còn fresh → dùng cache
        final cachedArticles = await _cacheService.getFromCache(category);

        if (cachedArticles != null && cachedArticles.isNotEmpty) {
          return FeedResponse.success(
            cachedArticles,
            fromCache: true,
          );
        } else {
          // Cache rỗng hoặc không có → fetch
          return await _fetchFromApi(category);
        }
      }
    } catch (e) {
      // Nếu lỗi, thử dùng cache
      final cachedArticles = await _cacheService.getFromCache(category);

      if (cachedArticles != null && cachedArticles.isNotEmpty) {
        return FeedResponse.success(
          cachedArticles,
          fromCache: true,
          cacheWarning: 'Using cached data due to network error',
        );
      }

      return FeedResponse.error('Error loading feed: ${e.toString()}');
    }
  }

  /// Fetch articles từ API và lưu vào cache
  Future<FeedResponse> _fetchFromApi(String category) async {
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

      // Build URL with category if not 'all'
      String url = '${Utils.baseUrl}/feed';
      if (category != 'all') {
        url += '?category=$category';
      }

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

        // Lưu vào cache
        await _cacheService.saveToCache(category, articles);

        return FeedResponse.success(articles, fromCache: false);
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

  /// Refresh feed (force fetch từ API)
  Future<FeedResponse> refreshFeed({String category = 'all'}) async {
    return getFeed(category: category, forceRefresh: true);
  }

  /// Kiểm tra có nên fetch không (cho app resume từ background)
  Future<bool> shouldFetchOnResume(String category) async {
    return await _cacheService.shouldFetch(category);
  }

  /// Clear cache cho một category
  Future<void> clearCache(String category) async {
    await _cacheService.clearCache(category);
  }

  /// Clear tất cả cache
  Future<void> clearAllCache() async {
    await _cacheService.clearAllCache();
  }

  /// Get cache info (for debugging)
  Future<Map<String, dynamic>> getCacheInfo(String category) async {
    return await _cacheService.getCacheInfo(category);
  }

  /// Fetch RSS mới từ nguồn rồi lấy feed
  ///
  /// Flow: POST /api/Rss/fetch → GET /api/feed
  ///
  /// [category] - Category để fetch
  /// [silent] - true = không show progress, false = show progress
  ///
  /// Returns: FeedResponse with isNewDataFetched flag
  Future<FeedResponseWithRssFetch> fetchRssAndGetFeed({
    String category = 'all',
    bool silent = false,
  }) async {
    try {
      // Step 1: Fetch RSS từ nguồn
      final rssResponse = await _rssService.fetchRss(category: category);

      if (!rssResponse.isSuccess) {
        // RSS fetch failed, try to get cached feed
        final feedResponse = await getFeed(category: category, forceRefresh: false);
        return FeedResponseWithRssFetch(
          feedResponse: feedResponse,
          rssFetchSuccess: false,
          rssFetchError: rssResponse.error,
          articlesCount: 0,
        );
      }

      // Step 2: Get feed từ database (sau khi RSS đã được crawl)
      // Force refresh để lấy data mới nhất
      final feedResponse = await getFeed(category: category, forceRefresh: true);

      return FeedResponseWithRssFetch(
        feedResponse: feedResponse,
        rssFetchSuccess: true,
        rssFetchMessage: rssResponse.message,
        articlesCount: rssResponse.articlesCount ?? 0,
      );
    } catch (e) {
      // Error, return cached feed if available
      final feedResponse = await getFeed(category: category, forceRefresh: false);
      return FeedResponseWithRssFetch(
        feedResponse: feedResponse,
        rssFetchSuccess: false,
        rssFetchError: 'Error: ${e.toString()}',
        articlesCount: 0,
      );
    }
  }
}

/// Response wrapper kết hợp RSS fetch + Feed get
class FeedResponseWithRssFetch {
  final FeedResponse feedResponse;
  final bool rssFetchSuccess;
  final String? rssFetchMessage;
  final String? rssFetchError;
  final int articlesCount;

  FeedResponseWithRssFetch({
    required this.feedResponse,
    required this.rssFetchSuccess,
    this.rssFetchMessage,
    this.rssFetchError,
    required this.articlesCount,
  });

  // Convenience getters
  bool get isSuccess => feedResponse.isSuccess;
  List<ArticleModel>? get articles => feedResponse.articles;
  String? get error => feedResponse.error ?? rssFetchError;
}

/// Response wrapper for Feed API
class FeedResponse {
  final List<ArticleModel>? articles;
  final String? error;
  final bool isSuccess;
  final bool fromCache;
  final String? cacheWarning;

  FeedResponse._({
    this.articles,
    this.error,
    required this.isSuccess,
    this.fromCache = false,
    this.cacheWarning,
  });

  factory FeedResponse.success(
    List<ArticleModel> articles, {
    bool fromCache = false,
    String? cacheWarning,
  }) {
    return FeedResponse._(
      articles: articles,
      isSuccess: true,
      fromCache: fromCache,
      cacheWarning: cacheWarning,
    );
  }

  factory FeedResponse.error(String error) {
    return FeedResponse._(
      error: error,
      isSuccess: false,
      fromCache: false,
    );
  }
}
