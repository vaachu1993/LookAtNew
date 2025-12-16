class UserDto {
  final String id;
  final String username;
  final String email;
  final String? avatarUrl;
  final bool isEmailVerified;
  final bool isGoogleAccount;
  final DateTime? createdAt;

  UserDto({
    required this.id,
    required this.username,
    required this.email,
    this.avatarUrl,
    required this.isEmailVerified,
    required this.isGoogleAccount,
    this.createdAt,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      isGoogleAccount: json['isGoogleAccount'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'avatarUrl': avatarUrl,
      'isEmailVerified': isEmailVerified,
      'isGoogleAccount': isGoogleAccount,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

