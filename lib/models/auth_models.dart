import 'user_dto.dart';

class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final UserDto user;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'user': user.toJson(),
    };
  }
}

class GoogleLoginResponse {
  final String accessToken;
  final String refreshToken;
  final UserDto user;

  GoogleLoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory GoogleLoginResponse.fromJson(Map<String, dynamic> json) {
    return GoogleLoginResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'user': user.toJson(),
    };
  }
}

class RefreshResponse {
  final String accessToken;
  final String refreshToken;

  RefreshResponse({
    required this.accessToken,
    required this.refreshToken,
  });

  factory RefreshResponse.fromJson(Map<String, dynamic> json) {
    return RefreshResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }
}

class RegisterRequest {
  final String username;
  final String email;
  final String password;
  final String? avatarUrl;

  RegisterRequest({
    required this.username,
    required this.email,
    required this.password,
    this.avatarUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'password': password,
      'avatarUrl': avatarUrl,
    };
  }
}

