import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/article_model.dart';

/// Service quản lý cache cho feed articles
/// - Cache riêng theo category
/// - Lưu lastFetchTime cho mỗi category
/// - Logic refresh dựa trên thời gian
class FeedCacheService {
  // Cache keys
  static const String _cachePrefix = 'feed_cache_';
  static const String _timePrefix = 'feed_time_';
  static const String _allCategoriesKey = 'all_categories';

  // Time thresholds
  static const Duration _freshDuration = Duration(minutes: 5);
  static const Duration _staleDuration = Duration(minutes: 10);

  // Singleton pattern
  static final FeedCacheService _instance = FeedCacheService._internal();
  factory FeedCacheService() => _instance;
  FeedCacheService._internal();

  // In-memory cache for faster access
  final Map<String, List<ArticleModel>> _memoryCache = {};
  final Map<String, DateTime> _memoryFetchTime = {};

  /// Lưu articles vào cache cho category
  Future<void> saveToCache(String category, List<ArticleModel> articles) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save to memory cache
      _memoryCache[category] = articles;
      _memoryFetchTime[category] = DateTime.now();

      // Save to persistent cache
      final articlesJson = articles.map((a) => a.toJson()).toList();
      await prefs.setString(
        '$_cachePrefix$category',
        jsonEncode(articlesJson),
      );

      // Save fetch time
      await prefs.setString(
        '$_timePrefix$category',
        DateTime.now().toIso8601String(),
      );

      // Track categories
      await _addCategoryToTracking(category);
    } catch (e) {
      print('Error saving cache for $category: $e');
    }
  }

  /// Lấy articles từ cache cho category
  Future<List<ArticleModel>?> getFromCache(String category) async {
    try {
      // Check memory cache first
      if (_memoryCache.containsKey(category)) {
        return _memoryCache[category];
      }

      // Load from persistent cache
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('$_cachePrefix$category');

      if (cachedJson == null) {
        return null;
      }

      final List<dynamic> jsonList = jsonDecode(cachedJson) as List<dynamic>;
      final articles = jsonList
          .map((json) => ArticleModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Update memory cache
      _memoryCache[category] = articles;

      // Load fetch time
      final timeStr = prefs.getString('$_timePrefix$category');
      if (timeStr != null) {
        _memoryFetchTime[category] = DateTime.parse(timeStr);
      }

      return articles;
    } catch (e) {
      print('Error loading cache for $category: $e');
      return null;
    }
  }

  /// Lấy thời gian fetch cuối cùng cho category
  Future<DateTime?> getLastFetchTime(String category) async {
    // Check memory first
    if (_memoryFetchTime.containsKey(category)) {
      return _memoryFetchTime[category];
    }

    // Load from persistent storage
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeStr = prefs.getString('$_timePrefix$category');

      if (timeStr != null) {
        final time = DateTime.parse(timeStr);
        _memoryFetchTime[category] = time;
        return time;
      }
    } catch (e) {
      print('Error loading fetch time for $category: $e');
    }

    return null;
  }

  /// Kiểm tra có nên fetch hay không
  /// Returns:
  /// - true: Cần fetch từ API
  /// - false: Có thể dùng cache
  Future<bool> shouldFetch(String category) async {
    final lastFetch = await getLastFetchTime(category);

    // Chưa có cache → fetch
    if (lastFetch == null) {
      return true;
    }

    final now = DateTime.now();
    final timeSinceLastFetch = now.difference(lastFetch);

    // >= 10 phút → fetch
    if (timeSinceLastFetch >= _staleDuration) {
      return true;
    }

    // < 5 phút → dùng cache
    if (timeSinceLastFetch < _freshDuration) {
      return false;
    }

    // 5-10 phút → dùng cache nhưng fetch background (optional)
    // Hiện tại return false, có thể customize
    return false;
  }

  /// Kiểm tra cache có còn fresh không
  Future<bool> isCacheFresh(String category) async {
    final lastFetch = await getLastFetchTime(category);

    if (lastFetch == null) {
      return false;
    }

    final now = DateTime.now();
    final timeSinceLastFetch = now.difference(lastFetch);

    return timeSinceLastFetch < _freshDuration;
  }

  /// Kiểm tra cache có stale không
  Future<bool> isCacheStale(String category) async {
    final lastFetch = await getLastFetchTime(category);

    if (lastFetch == null) {
      return true;
    }

    final now = DateTime.now();
    final timeSinceLastFetch = now.difference(lastFetch);

    return timeSinceLastFetch >= _staleDuration;
  }

  /// Xóa cache cho một category
  Future<void> clearCache(String category) async {
    try {
      // Clear memory
      _memoryCache.remove(category);
      _memoryFetchTime.remove(category);

      // Clear persistent
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_cachePrefix$category');
      await prefs.remove('$_timePrefix$category');
    } catch (e) {
      print('Error clearing cache for $category: $e');
    }
  }

  /// Xóa tất cả cache
  Future<void> clearAllCache() async {
    try {
      // Clear memory
      _memoryCache.clear();
      _memoryFetchTime.clear();

      // Clear persistent
      final prefs = await SharedPreferences.getInstance();
      final categories = await _getTrackedCategories();

      for (final category in categories) {
        await prefs.remove('$_cachePrefix$category');
        await prefs.remove('$_timePrefix$category');
      }

      await prefs.remove(_allCategoriesKey);
    } catch (e) {
      print('Error clearing all cache: $e');
    }
  }

  /// Track categories để dễ dàng clear all
  Future<void> _addCategoryToTracking(String category) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categories = await _getTrackedCategories();

      if (!categories.contains(category)) {
        categories.add(category);
        await prefs.setString(
          _allCategoriesKey,
          jsonEncode(categories),
        );
      }
    } catch (e) {
      print('Error tracking category: $e');
    }
  }

  /// Lấy danh sách categories đang được track
  Future<List<String>> _getTrackedCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categoriesJson = prefs.getString(_allCategoriesKey);

      if (categoriesJson == null) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(categoriesJson) as List<dynamic>;
      return jsonList.map((e) => e.toString()).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get cache info for debugging
  Future<Map<String, dynamic>> getCacheInfo(String category) async {
    final lastFetch = await getLastFetchTime(category);
    final articles = await getFromCache(category);
    final shouldFetchNow = await shouldFetch(category);
    final isFresh = await isCacheFresh(category);
    final isStale = await isCacheStale(category);

    return {
      'category': category,
      'hasCache': articles != null,
      'articleCount': articles?.length ?? 0,
      'lastFetchTime': lastFetch?.toIso8601String(),
      'minutesSinceLastFetch': lastFetch != null
          ? DateTime.now().difference(lastFetch).inMinutes
          : null,
      'shouldFetch': shouldFetchNow,
      'isFresh': isFresh,
      'isStale': isStale,
    };
  }
}

