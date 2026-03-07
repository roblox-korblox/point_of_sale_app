import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String username;
  final String password;
  final String role; // 'admin' or 'user'
  final String? name;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.username,
    required this.password,
    required this.role,
    this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'role': role,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      password: json['password'] as String,
      role: json['role'] as String,
      name: json['name'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? password,
    String? role,
    String? name,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, username, password, role, name, createdAt];
}

