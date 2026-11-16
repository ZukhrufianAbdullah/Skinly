import '../../../core/utils/date_parser.dart';

class User {
  final String id;
  final String username;
  final String name;
  final String email;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      username: json['username'] as String? ?? '',
      name: json['name'] as String,
      email: json['email'] as String,
      createdAt: parseServerDate(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'email': email,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}
