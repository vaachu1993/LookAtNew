import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lookat_app/Utils/Utils.dart';
import '../core/auth_storage.dart';
import '../models/article_model.dart';

/// Service để lấy danh sách categories từ API
class CategoryService {
  final AuthStorage _authStorage = AuthStorage();

  // Singleton pattern
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  /// Get danh sách categories từ database
  /// GET /api/Categories
  ///
  /// Returns: List of category names
  Future<CategoryResponse> getCategories() async {
    try {
      // Get token
      final token = await _authStorage.getAccessToken();

      if (token == null) {
        return CategoryResponse.error('No authentication token found');
      }

      // Build headers
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // Build URL
      String url = '${Utils.baseUrl}/Categories';

      // Make request
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      // Handle response
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;

        // Parse categories - có thể là string hoặc object
        final categories = jsonList.map((item) {
          if (item is String) {
            return item;
          } else if (item is Map<String, dynamic>) {
            // Nếu là object, lấy field 'name' hoặc 'category'
            return (item['name'] ?? item['category'] ?? item.toString()) as String;
          } else {
            return item.toString();
          }
        }).toList();

        return CategoryResponse.success(categories);
      } else if (response.statusCode == 401) {
        return CategoryResponse.error('Authentication failed. Please login again.');
      } else if (response.statusCode == 404) {
        // Nếu endpoint không tồn tại, trả về empty list thay vì error
        return CategoryResponse.success([]);
      } else {
        return CategoryResponse.error(
          'Failed to load categories. Status: ${response.statusCode}'
        );
      }
    } catch (e) {
      // Nếu có lỗi, trả về empty list thay vì error để không block UI
      return CategoryResponse.success([]);
    }
  }

  /// Extract unique categories từ danh sách articles
  /// Dùng khi API không có endpoint /api/Categories
  List<String> extractCategoriesFromArticles(List<ArticleModel> articles) {
    final categoriesSet = <String>{};

    for (var article in articles) {
      if (article.category.isNotEmpty) {
        categoriesSet.add(article.category);
      }
    }

    return categoriesSet.toList()..sort();
  }
}

/// Response wrapper cho category operations
class CategoryResponse {
  final bool isSuccess;
  final List<String>? categories;
  final String? error;

  CategoryResponse._({
    required this.isSuccess,
    this.categories,
    this.error,
  });

  factory CategoryResponse.success(List<String> categories) {
    return CategoryResponse._(
      isSuccess: true,
      categories: categories,
    );
  }

  factory CategoryResponse.error(String error) {
    return CategoryResponse._(
      isSuccess: false,
      error: error,
    );
  }
}

