import '../user_dto.dart';

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

