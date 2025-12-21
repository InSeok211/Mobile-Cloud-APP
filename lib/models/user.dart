// 사용자 모델
class User {
  final int? id;
  final String email;
  final String password;
  final String? name;
  final DateTime createdAt;

  User({
    this.id,
    required this.email,
    required this.password,
    this.name,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Map으로 변환 (데이터베이스 저장용)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Map에서 User 객체 생성 (데이터베이스 읽기용)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      email: map['email'],
      password: map['password'],
      name: map['name'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  // 복사본 생성
  User copyWith({
    int? id,
    String? email,
    String? password,
    String? name,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      password: password ?? this.password,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

