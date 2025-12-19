import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/auth_storage.dart';
import '../models/favorite_model.dart';

class FavoriteService {
  // Base URL for ASP.NET Core backend
  static const String _baseUrl = 'http://10.0.2.2:5201/api';

  final AuthStorage _authStorage = AuthStorage();

  // Singleton pattern
  static final FavoriteService _instance = FavoriteService._internal();
  factory FavoriteService() => _instance;
  FavoriteService._internal();

  /// Get all favorites
  /// GET /api/favorites
  Future<FavoriteResponse> getFavorites() async {
    try {
      // Get token
      final token = await _authStorage.getAccessToken();

      if (token == null) {
        return FavoriteResponse.error('No authentication token found');
      }

      // Build headers
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // Make request
      final response = await http.get(
        Uri.parse('$_baseUrl/favorites'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      // Handle response
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
        final favorites = jsonList
            .map((json) => FavoriteModel.fromJson(json as Map<String, dynamic>))
            .toList();

        return FavoriteResponse.success(favorites);
      } else if (response.statusCode == 401) {
        return FavoriteResponse.error('Authentication failed. Please login again.');
      } else {
        return FavoriteResponse.error(
          'Failed to load favorites. Status: ${response.statusCode}'
        );
      }
    } catch (e) {
      return FavoriteResponse.error('Error loading favorites: ${e.toString()}');
    }
  }

  /// Add article to favorites
  /// POST /api/favorites
  Future<AddFavoriteResponse> addFavorite(String articleId) async {
    try {
      // Get token
      final token = await _authStorage.getAccessToken();

      if (token == null) {
        return AddFavoriteResponse.error('No authentication token found');
      }

      // Build headers
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // Build body
      final body = jsonEncode({
        'articleId': articleId,
      });

      // Make request
      final response = await http.post(
        Uri.parse('$_baseUrl/favorites'),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 15));

      // Handle response
      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final favorite = FavoriteModel.fromJson(json);
        return AddFavoriteResponse.success(favorite);
      } else if (response.statusCode == 401) {
        return AddFavoriteResponse.error('Authentication failed. Please login again.');
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final message = json['message'] as String? ?? 'Bad request';
        return AddFavoriteResponse.error(message);
      } else {
        return AddFavoriteResponse.error(
          'Failed to add favorite. Status: ${response.statusCode}'
        );
      }
    } catch (e) {
      return AddFavoriteResponse.error('Error adding favorite: ${e.toString()}');
    }
  }

  /// Remove article from favorites
  /// DELETE /api/favorites/{id}
  Future<RemoveFavoriteResponse> removeFavorite(String favoriteId) async {
    try {
      // Get token
      final token = await _authStorage.getAccessToken();

      if (token == null) {
        return RemoveFavoriteResponse.error('No authentication token found');
      }

      // Build headers
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // Make request
      final response = await http.delete(
        Uri.parse('$_baseUrl/favorites/$favoriteId'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      // Handle response
      if (response.statusCode == 200 || response.statusCode == 204) {
        return RemoveFavoriteResponse.success();
      } else if (response.statusCode == 401) {
        return RemoveFavoriteResponse.error('Authentication failed. Please login again.');
      } else if (response.statusCode == 404) {
        return RemoveFavoriteResponse.error('Favorite not found');
      } else {
        return RemoveFavoriteResponse.error(
          'Failed to remove favorite. Status: ${response.statusCode}'
        );
      }
    } catch (e) {
      return RemoveFavoriteResponse.error('Error removing favorite: ${e.toString()}');
    }
  }
}

/// Response wrapper for getting favorites
class FavoriteResponse {
  final List<FavoriteModel>? favorites;
  final String? error;
  final bool isSuccess;

  FavoriteResponse._({
    this.favorites,
    this.error,
    required this.isSuccess,
  });

  factory FavoriteResponse.success(List<FavoriteModel> favorites) {
    return FavoriteResponse._(
      favorites: favorites,
      isSuccess: true,
    );
  }

  factory FavoriteResponse.error(String error) {
    return FavoriteResponse._(
      error: error,
      isSuccess: false,
    );
  }
}

/// Response wrapper for adding favorite
class AddFavoriteResponse {
  final FavoriteModel? favorite;
  final String? error;
  final bool isSuccess;

  AddFavoriteResponse._({
    this.favorite,
    this.error,
    required this.isSuccess,
  });

  factory AddFavoriteResponse.success(FavoriteModel favorite) {
    return AddFavoriteResponse._(
      favorite: favorite,
      isSuccess: true,
    );
  }

  factory AddFavoriteResponse.error(String error) {
    return AddFavoriteResponse._(
      error: error,
      isSuccess: false,
    );
  }
}

/// Response wrapper for removing favorite
class RemoveFavoriteResponse {
  final String? error;
  final bool isSuccess;

  RemoveFavoriteResponse._({
    this.error,
    required this.isSuccess,
  });

  factory RemoveFavoriteResponse.success() {
    return RemoveFavoriteResponse._(
      isSuccess: true,
    );
  }

  factory RemoveFavoriteResponse.error(String error) {
    return RemoveFavoriteResponse._(
      error: error,
      isSuccess: false,
    );
  }
}

