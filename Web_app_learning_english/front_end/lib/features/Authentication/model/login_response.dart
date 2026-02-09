class LoginResponse {
  final String message;
  final int userId;
  final String username;

  LoginResponse({
    required this.message,
    required this.userId,
    required this.username,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      message: json['message'],
      userId: json['userId'],
      username: json['username'],
    );
  }
}
