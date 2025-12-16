class User {
  final String id;
  final String email;
  final String username;
  final String? avatarUrl;
  final bool isVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.email,
    required this.username,
    this.avatarUrl,
    this.isVerified = false,
    this.createdAt,
    this.updatedAt,
  });

  // Factory constructor from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
      isVerified: json['isVerified'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'avatarUrl': avatarUrl,
      'isVerified': isVerified,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Immutable copyWith method
  User copyWith({
    String? id,
    String? email,
    String? username,
    String? avatarUrl,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, username: $username, isVerified: $isVerified)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is User &&
        other.id == id &&
        other.email == email &&
        other.username == username &&
        other.avatarUrl == avatarUrl &&
        other.isVerified == isVerified &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        email.hashCode ^
        username.hashCode ^
        avatarUrl.hashCode ^
        isVerified.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}



