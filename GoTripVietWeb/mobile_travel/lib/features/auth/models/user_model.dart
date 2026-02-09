class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final List<String> roles;
  final String? token; // Token is usually returned on login
  final String? avatar;
  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.roles,
    this.token,
    this.avatar,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Check if the user object is nested inside a 'user' key (common in login responses)
    final userData = json['user'] != null ? json['user'] : json;

    return UserModel(
      id: userData['_id'] ?? '',
      email: userData['email'] ?? '',
      fullName: userData['fullName'] ?? 'User',
      phone: userData['phone'],
      roles: userData['roles'] != null
          ? List<String>.from(userData['roles'])
          : ['user'],
      token: json['token'], // Token might be at the root level of response
      avatar: json['avatar'] ?? json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'roles': roles,
      'avatar': avatar,
    };
  }
}
