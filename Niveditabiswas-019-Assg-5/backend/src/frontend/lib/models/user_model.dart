class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'admin' | 'student'
  final String photoUrl;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.photoUrl = '',
  });

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isStudent => role.toLowerCase() == 'student';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? json['displayName'] ?? 'User',
      role: json['role'] ?? 'student',
      photoUrl: json['photoUrl'] ?? json['photoURL'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'photoUrl': photoUrl,
    };
  }
}
