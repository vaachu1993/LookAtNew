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

