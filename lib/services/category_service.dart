import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lookat_app/Utils/Utils.dart';
import '../core/auth_storage.dart';
import '../models/article_model.dart';
import '../models/category_model.dart';

/// Service để quản lý categories với RSS sources
class CategoryService {
  final AuthStorage _authStorage = AuthStorage();

  // Singleton pattern
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  /// Get tất cả categories với RSS sources
  /// GET /api/Categories
  ///
  /// Returns: List of CategoryModel with RSS sources
  Future<CategoryListResponse> getCategories() async {
    try {
      // Get token
      final token = await _authStorage.getAccessToken();

      if (token == null) {
        return CategoryListResponse.error('No authentication token found');
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

        // Parse categories with RSS sources
        final categories = jsonList
            .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
            .toList();

        return CategoryListResponse.success(categories);
      } else if (response.statusCode == 401) {
        return CategoryListResponse.error('Authentication failed. Please login again.');
      } else if (response.statusCode == 404) {
        // Nếu endpoint không tồn tại, trả về empty list
        return CategoryListResponse.success([]);
      } else {
        return CategoryListResponse.error(
          'Failed to load categories. Status: ${response.statusCode}'
        );
      }
    } catch (e) {
      return CategoryListResponse.error('Error loading categories: ${e.toString()}');
    }
  }

  /// Get category by ID
  /// GET /api/Categories/{id}
  Future<CategoryDetailResponse> getCategoryById(String id) async {
    try {
      final token = await _authStorage.getAccessToken();

      if (token == null) {
        return CategoryDetailResponse.error('No authentication token found');
      }

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      String url = '${Utils.baseUrl}/Categories/$id';

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final category = CategoryModel.fromJson(json);
        return CategoryDetailResponse.success(category);
      } else if (response.statusCode == 404) {
        return CategoryDetailResponse.error('Category not found');
      } else {
        return CategoryDetailResponse.error(
          'Failed to load category. Status: ${response.statusCode}'
        );
      }
    } catch (e) {
      return CategoryDetailResponse.error('Error loading category: ${e.toString()}');
    }
  }

  /// Extract unique category names từ danh sách articles
  /// Dùng khi cần lấy categories từ articles thay vì API
  List<String> extractCategoriesFromArticles(List<ArticleModel> articles) {
    final categoriesSet = <String>{};

    for (var article in articles) {
      if (article.category.isNotEmpty) {
        categoriesSet.add(article.category);
      }
    }

    return categoriesSet.toList()..sort();
  }

  /// Get danh sách category names (không có RSS sources)
  /// Tiện dụng cho UI dropdown/filter
  Future<CategoryNamesResponse> getCategoryNames() async {
    final response = await getCategories();

    if (response.isSuccess && response.categories != null) {
      final names = response.categories!.map((cat) => cat.name).toList();
      return CategoryNamesResponse.success(names);
    } else {
      return CategoryNamesResponse.error(response.error ?? 'Failed to load categories');
    }
  }
}

/// Response wrapper cho danh sách categories
class CategoryListResponse {
  final bool isSuccess;
  final List<CategoryModel>? categories;
  final String? error;

  CategoryListResponse._({
    required this.isSuccess,
    this.categories,
    this.error,
  });

  factory CategoryListResponse.success(List<CategoryModel> categories) {
    return CategoryListResponse._(
      isSuccess: true,
      categories: categories,
    );
  }

  factory CategoryListResponse.error(String error) {
    return CategoryListResponse._(
      isSuccess: false,
      error: error,
    );
  }
}

/// Response wrapper cho single category
class CategoryDetailResponse {
  final bool isSuccess;
  final CategoryModel? category;
  final String? error;

  CategoryDetailResponse._({
    required this.isSuccess,
    this.category,
    this.error,
  });

  factory CategoryDetailResponse.success(CategoryModel category) {
    return CategoryDetailResponse._(
      isSuccess: true,
      category: category,
    );
  }

  factory CategoryDetailResponse.error(String error) {
    return CategoryDetailResponse._(
      isSuccess: false,
      error: error,
    );
  }
}

/// Response wrapper cho category names only
class CategoryNamesResponse {
  final bool isSuccess;
  final List<String>? names;
  final String? error;

  CategoryNamesResponse._({
    required this.isSuccess,
    this.names,
    this.error,
  });

  factory CategoryNamesResponse.success(List<String> names) {
    return CategoryNamesResponse._(
      isSuccess: true,
      names: names,
    );
  }

  factory CategoryNamesResponse.error(String error) {
    return CategoryNamesResponse._(
      isSuccess: false,
      error: error,
    );
  }
}

